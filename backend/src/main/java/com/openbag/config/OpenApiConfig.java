package com.openbag.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeIn;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.info.Contact;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.info.License;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import io.swagger.v3.oas.annotations.servers.Server;
import org.springframework.context.annotation.Configuration;

@Configuration
@OpenAPIDefinition(
    info = @Info(
        title = "OpenBag API",
        version = "1.0.0",
        description = """
            API do OpenBag - Sistema de gestão de pedidos e delivery
            
            ## Funcionalidades Principais
            
            - **Autenticação**: Login e registro de usuários com JWT
            - **Restaurantes**: Gestão completa de restaurantes, produtos e categorias
            - **Pedidos**: Criação e acompanhamento de pedidos
            - **Produtos Globais**: Catálogo centralizado de produtos
            - **Combos**: Criação de combos personalizados
            - **Upload de Imagens**: Upload de imagens de produtos, restaurantes e perfis
            
            ## Autenticação
            
            A maioria dos endpoints requer autenticação via token JWT. 
            
            1. Faça login em `/api/auth/login` com email e senha
            2. Copie o `accessToken` retornado
            3. Clique no botão "Authorize" no topo desta página
            4. Insira o token no formato: `Bearer {seu_token}`
            5. Clique em "Authorize" e depois "Close"
            
            ## Roles e Permissões
            
            - **ADMIN**: Acesso completo ao sistema
            - **RESTAURANT**: Gerenciamento de restaurantes e produtos
            - **CUSTOMER**: Realização de pedidos
            - **DELIVERY**: Gestão de entregas
            
            ## Paginação
            
            Endpoints que retornam listas suportam paginação via parâmetros:
            - `page`: Número da página (inicia em 0)
            - `size`: Quantidade de itens por página (padrão: 20)
            - `sort`: Campo e direção de ordenação (ex: `name,asc`)
            """,
        contact = @Contact(
            name = "Equipe OpenBag",
            email = "contato@openbag.com",
            url = "https://openbag.com"
        ),
        license = @License(
            name = "MIT License",
            url = "https://opensource.org/licenses/MIT"
        )
    ),
    servers = {
        @Server(
            description = "Servidor de Desenvolvimento Local",
            url = "http://localhost:8080/api"
        ),
        @Server(
            description = "Servidor de Produção",
            url = "https://api.openbag.com"
        )
    }
)
@SecurityScheme(
    name = "bearerAuth",
    description = "Autenticação JWT. Obtenha o token via /api/auth/login e use no formato: Bearer {token}",
    scheme = "bearer",
    type = SecuritySchemeType.HTTP,
    bearerFormat = "JWT",
    in = SecuritySchemeIn.HEADER
)
public class OpenApiConfig {
}
