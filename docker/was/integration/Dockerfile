FROM openjdk:21-jdk-slim

WORKDIR /app

EXPOSE 8080

COPY *.jar ./

ENTRYPOINT ["java", "-jar", "integration-0.0.1-SNAPSHOT.jar"]