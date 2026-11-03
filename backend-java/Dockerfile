# Imagem do back-end Smart HAS. Os testes rodam antes, em job proprio do pipeline.
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn -B -q -DskipTests package

FROM eclipse-temurin:17-jre
RUN useradd --create-home --uid 10001 smarthas
WORKDIR /app
COPY --from=build /build/target/backend-1.0.0.jar app.jar
# O H2 da Fase 5 grava em ./data
RUN mkdir data && chown smarthas:smarthas data
USER smarthas
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
