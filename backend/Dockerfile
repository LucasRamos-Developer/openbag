# Imagem do backend em dois estágios: o JDK e o Maven só existem na construção; a imagem final tem só o JRE e o jar,
# e roda com um usuário sem privilégios.

# ============= Construção =============
FROM eclipse-temurin:25-jdk-jammy AS build

RUN apt-get update && apt-get install -y --no-install-recommends maven && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# As dependências primeiro: mudar só o código não baixa tudo de novo
COPY pom.xml .
RUN mvn -q dependency:go-offline

COPY src ./src
RUN mvn -q clean package -DskipTests && cp target/openbag-backend-*.jar app.jar

# ============= Execução =============
FROM eclipse-temurin:25-jre-jammy

RUN groupadd --system openbag && useradd --system --gid openbag --home-dir /app --shell /usr/sbin/nologin openbag

WORKDIR /app
COPY --from=build /build/app.jar app.jar
# Uploads e logs gravados pelo backend (monte um volume em /app/uploads em produção)
RUN mkdir -p uploads logs && chown -R openbag:openbag /app

USER openbag

EXPOSE 8080

# Perfil de produção por padrão: exige os segredos por variável de ambiente (ver application-prod.properties).
# O docker-compose de desenvolvimento troca para o perfil docker
ENV SPRING_PROFILES_ACTIVE=prod

CMD ["java", "-jar", "app.jar"]
