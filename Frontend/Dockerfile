
# Imagen base para compilar
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS building-stage

# Directorio de trabajo 
WORKDIR /src

# Se copian los archivos base del proyecto
COPY --link *.csproj .
COPY --link *.sln .

# Descarga y valida las dependencias
RUN dotnet restore

# Copiar todo el código restante
COPY . .

# Crea el publish al directorio /publish
RUN dotnet publish --no-restore -o /publish

# Imagen de ejecución
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS base

WORKDIR /app

# Copiar el resultante de la imagen anterior
COPY --link --from=building-stage /publish .

# Puerto
EXPOSE 8080

# Interfaz
ENV ASPNETCORE_ENVIRONMENT=Development

# Arranque
ENTRYPOINT ["./Frontend-Contenedores"]