# =============================================================================
#  API BACKEND (microservices metier) - image Docker
#  Construction en deux etapes : compilation Maven puis execution legere (JRE).
#  Le contexte de build est le dossier backend_java (projet Maven multi-modules).
# =============================================================================

# --- Etape 1 : compilation avec Maven + JDK 21 -------------------------------
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /projet

# Poms d'abord : permet a Docker de mettre en cache le telechargement des
# dependances tant que les poms ne changent pas.
COPY pom.xml ./
COPY .mvn/ ./.mvn/
COPY api-backend/pom.xml api-backend/
COPY api-frontend/pom.xml api-frontend/

# Code source puis compilation du seul module api-backend (-am = « also make »
# construit aussi le module parent dont il depend). Tests ignores pour le build.
COPY api-backend/src api-backend/src
RUN mvn -q -pl api-backend -am clean package -DskipTests

# --- Etape 2 : execution (image legere, sans Maven ni JDK) -------------------
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /projet/api-backend/target/api-backend.jar app.jar

# Port interne des microservices metier (non publie vers l'exterieur)
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
