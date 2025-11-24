FROM eclipse-temurin:11-jre-alpine

LABEL maintainer="ecommerce-project"

WORKDIR /app

ARG JAR_FILE=proxy-client/target/*.jar
COPY ${JAR_FILE} app.jar

EXPOSE 8900

ENTRYPOINT ["java", "-jar", "app.jar"]
