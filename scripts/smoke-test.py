#!/usr/bin/env python3
"""Check the running Compose stack. Writes require --write-test-data (for disposable CI)."""
import argparse
import json
import os
from pathlib import Path
import time
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen
import uuid


def request(url, method="GET", data=None, token=None, expected=(200,)):
    headers = {"Accept": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    body = None
    if data is not None:
        body = json.dumps(data).encode()
        headers["Content-Type"] = "application/json"
    try:
        with urlopen(Request(url, data=body, headers=headers, method=method), timeout=15) as response:
            status, content = response.status, response.read()
    except HTTPError as error:
        status, content = error.code, error.read()
    if status not in expected:
        raise AssertionError(f"{method} {url}: HTTP {status}; expected {expected}")
    if not content:
        return None
    try:
        return json.loads(content)
    except (ValueError, UnicodeDecodeError):
        return content.decode(errors="replace")


def eventually(label, check, timeout=180):
    deadline = time.monotonic() + timeout
    last_error = None
    while time.monotonic() < deadline:
        try:
            result = check()
            if result:
                print("OK:", label, flush=True)
                return result
        except (AssertionError, URLError, TimeoutError, OSError) as error:
            last_error = error
        time.sleep(3)
    raise AssertionError(f"Timeout: {label}. Last error: {last_error}")


def settings():
    values = {}
    env_path = Path(__file__).resolve().parents[1] / ".env"
    if env_path.exists():
        for line in env_path.read_text().splitlines():
            if line.strip() and not line.lstrip().startswith("#") and "=" in line:
                key, value = line.split("=", 1)
                value = value.strip()
                if len(value) > 1 and value[0] == value[-1] and value[0] in "\"'":
                    value = value[1:-1]
                values[key.strip()] = value
    values.update(os.environ)
    return values


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write-test-data", action="store_true")
    args = parser.parse_args()
    env = settings()
    base = "http://localhost:4200/api/"
    services = {"discovery-server": 9001, "api-gateway": 9002, "auth-service": 9003,
                "catalog-service": 9004, "design-service": 9005, "inventory-service": 9006,
                "production-service": 9007, "sales-service": 9008, "report-service": 9009,
                "notification-service": 9010}
    for service, port in services.items():
        eventually(service + " health", lambda port=port:
                   request(f"http://localhost:{port}/actuator/health").get("status") == "UP")
    html = request("http://localhost:4200/")
    assert isinstance(html, str) and "<app-root" in html, "Angular index not served"
    for service in services:
        if service in ("discovery-server", "api-gateway"):
            continue
        eventually("nginx -> Gateway -> " + service, lambda service=service:
                   request(base + service + "/actuator/health").get("status") == "UP")

    def api(path, **kwargs):
        return request(base + path, **kwargs)

    login = api("auth-service/api/v1/auth/login", method="POST", data={
        "nomusuario": env["SIGIP_ADMIN_USERNAME"], "password": env["SIGIP_ADMIN_PASSWORD"]})
    admin = login["token"]
    assert admin and "ADMIN" in login["usuario"]["roles"], "Admin login/role failed"
    api("auth-service/api/v1/auth/me", token=admin)
    assert isinstance(api("catalog-service/api/v1/servicios"), list)
    for path in ("auth-service/api/v1/usuarios", "sales-service/api/v1/pedidos",
                 "design-service/api/v1/disenos", "inventory-service/api/v1/insumos",
                 "production-service/api/v1/ordenes-produccion",
                 "notification-service/api/v1/notificaciones"):
        assert isinstance(api(path, token=admin), list), path
    dashboard = api("report-service/api/v1/reportes/dashboard", token=admin)
    assert dashboard["ventas"] is not None, "Report -> Sales failed"
    assert isinstance(api("report-service/api/v1/reportes/inventario-critico", token=admin), list)
    api("inventory-service/api/v1/insumos", expected=(401,))
    print("OK: admin login, protected routes and Report -> Sales/Inventory", flush=True)

    if args.write_test_data:
        write_checks(api, admin)
    eventually("Prometheus ready", lambda: request("http://localhost:9090/-/ready"))
    eventually("Grafana database", lambda: request("http://localhost:3000/api/health").get("database") == "ok")
    print("SIGIP integrated smoke test PASSED", flush=True)


def write_checks(api, admin):
    suffix = uuid.uuid4().hex[:12]
    username, password = "smoke_" + suffix, uuid.uuid4().hex
    cleanup = []
    try:
        user = api("auth-service/api/v1/auth/registro", method="POST", expected=(201,), data={
            "nomusuario": username, "email": username + "@example.invalid", "password": password,
            "nombres": "Smoke", "apellidos": "Test"})
        cleanup.append("auth-service/api/v1/usuarios/" + str(user["idusuario"]))
        client = api("auth-service/api/v1/auth/login", method="POST",
                     data={"nomusuario": username, "password": password})["token"]
        api("inventory-service/api/v1/insumos", token=client, expected=(403,))
        category_path = "catalog-service/api/v1/categorias"
        category = api(category_path, method="POST", token=admin, expected=(201,),
                       data={"nombre": "Smoke " + suffix, "descripcion": "CI integration"})
        category_path += "/" + str(category["idcategoria"])
        cleanup.append(category_path)
        api(category_path, method="PUT", token=admin,
            data={"nombre": "Smoke updated " + suffix, "descripcion": "CI integration"})
        assert api(category_path)["nombre"] == "Smoke updated " + suffix
        service = api("catalog-service/api/v1/servicios", method="POST", token=admin, expected=(201,),
                      data={"nombre": "Smoke " + suffix, "precioBase": 10, "requiereCotizacion": False,
                            "idcategoria": category["idcategoria"], "activo": True})
        cleanup.append("catalog-service/api/v1/servicios/" + str(service["idservicio"]))
        payload = {"idservicio": service["idservicio"], "cantidad": 2, "especificaciones": "CI smoke"}
        order = api("sales-service/api/v1/pedidos", method="POST", token=client,
                    expected=(201,), data=payload)
        order_path = "sales-service/api/v1/pedidos/" + str(order["idpedido"])
        cleanup.append(order_path)
        assert order["cliente"] == username and order["total"] == 20, "Sales -> Catalog failed"
        payload["cantidad"] = 3
        api(order_path, method="PUT", token=client, data=payload)
        assert api(order_path, token=client)["total"] == 30, "Order update/persistence failed"
        notice = eventually("Sales -> RabbitMQ -> Notification", lambda: next(
            (n for n in api("notification-service/api/v1/notificaciones", token=client)
             if n["idpedido"] == order["idpedido"]), None), timeout=60)
        cleanup.append("notification-service/api/v1/notificaciones/" + str(notice["idnotificacion"]))
        assert api("report-service/api/v1/reportes/dashboard", token=admin)["ventas"]["totalPedidos"] >= 1
        print("OK: client permissions, catalog CRUD, order CRUD and persisted event", flush=True)
    finally:
        for path in reversed(cleanup):
            api(path, method="DELETE", token=admin, expected=(200, 204, 404))


if __name__ == "__main__":
    main()
