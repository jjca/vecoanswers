
# Imagen base para compilar
FROM mcr.microsoft.com/dotnet/sdk:8.0

# Instalar dependencia dotnet ef 

RUN dotnet tool install --global dotnet-ef

# Directorio de trabajo 
WORKDIR /src

# Se copian los archivos base del proyecto
COPY --link *.csproj .

COPY --link *.sln .

# Descarga y valida las dependencias del proyecto
RUN dotnet restore

# Copiar todo el código restante
COPY . .

# Crea el publish al directorio /publish
RUN dotnet publish --no-restore -o /publish

# Path para dotnet ef
ENV PATH="$PATH:/root/.dotnet/tools" 

# Puerto
EXPOSE 5198

# Variable de ambiente para el puerto
ENV ASPNETCORE_HTTP_PORTS=5198

ENTRYPOINT ["/src/start.sh"]
