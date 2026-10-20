package pe.edu.cibertec.sigip.gateway;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.cloud.gateway.route.Route;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("test")
class ApiGatewayApplicationTest {

    @Autowired
    private RouteLocator routeLocator;

    @Test
    @DisplayName("Las 8 rutas usan balanceo de carga (lb://) hacia los microservicios")
    void rutasConBalanceo() {
        List<Route> rutas = routeLocator.getRoutes().collectList().block();
        assertThat(rutas).hasSize(8);
        assertThat(rutas).allSatisfy(r -> assertThat(r.getUri().getScheme()).isEqualTo("lb"));
        assertThat(rutas).extracting(Route::getId).contains("auth-service", "sales-service", "report-service");
    }
}
