FROM eclipse-temurin:11-jre-alpine

LABEL maintainer="ecommerce-project"

WORKDIR /app

ARG JAR_FILE=order-service/target/*.jar
COPY ${JAR_FILE} app.jar

EXPOSE 8300

ENTRYPOINT ["java", "-jar", "app.jar"]
