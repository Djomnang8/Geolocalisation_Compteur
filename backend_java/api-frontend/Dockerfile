# =============================================================================
#  API FRONTEND (passerelle BFF) - image Docker
#  Seule API publiee vers l'exterieur (port 8080). Elle appelle l'API Backend
#  par le reseau interne Docker (http://api-backend:8081).
#  Le contexte de build est le dossier backend_java (projet Maven multi-modules).
# =============================================================================

# --- Etape 1 : compilation avec Maven + JDK 21 -------------------------------
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /projet

COPY pom.xml ./
COPY .mvn/ ./.mvn/
COPY api-backend/pom.xml api-backend/
COPY api-frontend/pom.xml api-frontend/

COPY api-frontend/src api-frontend/src
RUN mvn -q -pl api-frontend -am clean package -DskipTests

# --- Etape 2 : execution (image legere) --------------------------------------
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /projet/api-frontend/target/api-frontend.jar app.jar

# Seule porte d'entree exposee a l'application mobile
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
