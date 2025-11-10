# FROM eclipse-temurin:21-jre-alpine

# RUN addgroup -S app && adduser -S app -G app
# USER app
# WORKDIR /app

# ARG JAR_FILE=target/backend-0.0.1-SNAPSHOT.jar
# COPY ${JAR_FILE} app.jar

# EXPOSE 8080
# ENV JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom"
# ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar app.jar"]

FROM maven:3.9.9-eclipse-temurin-21-alpine AS build

WORKDIR /build

COPY pom.xml .

RUN mvn -B dependency:go-offline

COPY src ./src

RUN mvn -B clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine

RUN addgroup -S app && adduser -S app -G app
USER app
WORKDIR /app

COPY --from=build /build/target/backend-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080
ENV JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom"
ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar app.jar"]
