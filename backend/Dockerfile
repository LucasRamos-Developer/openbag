# Use Eclipse Temurin 25 como base
FROM eclipse-temurin:25-jdk-jammy

# Instalar Maven
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*

# Definir diretório de trabalho
WORKDIR /app

# Copiar arquivos do projeto
COPY pom.xml .
COPY src ./src

# Construir o projeto
RUN mvn clean package -DskipTests && cp target/openbag-backend-*.jar app.jar

# Expor a porta
EXPOSE 8080

# Perfil de produção por padrão: exige os segredos por variável de ambiente (ver application-prod.properties).
# O docker-compose de desenvolvimento troca para o perfil docker
ENV SPRING_PROFILES_ACTIVE=prod

# Comando para executar a aplicação
CMD ["java", "-jar", "app.jar"]
