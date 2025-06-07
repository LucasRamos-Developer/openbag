# Use OpenJDK 21 como base
FROM openjdk:21-jdk-slim

# Instalar Maven
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*

# Definir diretório de trabalho
WORKDIR /app

# Copiar arquivos do projeto
COPY pom.xml .
COPY src ./src

# Construir o projeto
RUN mvn clean package -DskipTests

# Expor a porta
EXPOSE 8080

# Comando para executar a aplicação
CMD ["java", "-jar", "target/openbag-backend-0.0.1-SNAPSHOT.jar"]
