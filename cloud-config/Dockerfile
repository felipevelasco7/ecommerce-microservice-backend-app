FROM eclipse-temurin:11-jre-alpine

LABEL maintainer="ecommerce-project"

WORKDIR /app

ARG JAR_FILE=cloud-config/target/*.jar
COPY ${JAR_FILE} app.jar

EXPOSE 9296

ENTRYPOINT ["java", "-jar", "app.jar"]
