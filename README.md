# Entregables

## API

Se despliega usando la imagen definida en el Dockerfile dentro del repositorio de APIContainer. La imagen base es `mcr.microsoft.com/dotnet/sdk:8.0-alpine`

## Frontend

Se despliega usando la imagen definida en el Dockerfile dentro del repositorio de Frontend-Contenedores. La imagen base es `docker pull mcr.microsoft.com/dotnet/sdk:8.0-alpine`
## Base de datos

Se despliega usando la imagen predeterminada de SQL Server 2022 para Linux proveída por Microsoft. El almacenamiento predefinido de la base de datos es en el directorio `sqlserver` donde fue clonado este repositorio.

Se asume que el usuario a usar para inicializar la base de datos es `sa` y se define su contraseña en el archivo `db_password`, ver siguiente sección.

## Ejecución del stack

Para ejecutar el stack, se deben cumplir los siguientes prerrequisitos:

1. Contar con Docker instalado en su última versión
2. Clonar el repositorio actual
3. Tener acceso al Registry donde se alojan las imágenes
4. Modificar el archivo de ambiente para el backend, `.env.example` con los parámetros requeridos y renombrar a `.env_backend`.
5. Crear el archivo `db_password` y escribir dentro contraseña deseada para el usuario `sa` de la base de datos. Este archivo únicamente contiene la contraseña en texto plano.
6. Crear el directorio para el almacenamiento de los datos del SQLServer. Para este proyecto está de forma predeterminada en: `sqlserver/data` relativo a donde fue clonado el repositorio.
7. Asignar los permisos al UID 10001 correspondiente con el usuario `mssql` dentro del contenedor a la carpeta `sqlserver/data`: `chown -R 10001 sqlserver`.
8. Configurar el archivo `appsettings.json` en el directorio donde se encuentra el archivo `docker-compose.yaml` con los parámetros de conexión correspondientes.
9. Ejecutar `docker compose up`.

## Workflow

El workflow de GitHub Actions se implementó 

## Variables de ambiente

Valores predeterminados de las variables de ambiente:

```
- MIGRATE=false
- MSSQL_USER=sa
- MSSQL_HOSTPORT=sqlserver,1433
- MSSQL_DATABASE=Veconinter
```

### MIGRATE

Variable para indicar si se requiere aplicar migraciones sobre la base de datos. Para ejecutar el comando `dotnet ef database update` en el script de inicio `start.sh` del contenedor del backend se debe establecer en `true` a la variable `MIGRATE`.

### MSSQL_USER

Usuario de conexión de la base de datos.

### MSSQL_HOSTPORT

Cadena donde se incluye el hostname y puerto del Servidor de SQL Server. Ej: `10.1.1.4,1433` o `servidorsql.local,1433`. En caso de usar instancias, ignorar el puerto. Se requiere un DNS funcional y configurado, lo cual, no fue contemplado en este caso.

### MSSQL_DATABASE

Nombre de la base de datos sobre la cual trabajará el backend.

### ASPNETCORE_ENVIRONMENT

Si se establece en `Development` activa el Swagger del API. Si se deja en blanco, se considera el ambiente de producción.

## Secretos

### appsettings.json

Incluye la configuración de conexión hacia la base de datos. Es usado únicamente por el contenedor de Backend y se requiere configurar manualmente. El archivo es proveído así:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Server=$MSSQLHOSTPORT;Trusted_Connection=False;user id=$MSSQL_USER;password=$MSSQL_SA_PASSWORD;Database=$MSSQL_DATABASE;TrustServerCertificate=True;"
  }
}
```

Únicamente debe actualizarse el parámetro `DefaultConnection`. Por ejemplo:

```json
"DefaultConnection": "Server=127.0.0.1,1433;Trusted_Connection=False;user id=sa;password=Contraseña12345;Database=db_base;TrustServerCertificate=True;"
```

### db_password

Archivo que contiene únicamente la contraseña del usuario `sa` del SQL Server. Es usada por el contendeor de SQLServer.

## Detalles técnicos

- Se observó que era requerido crear una nueva migración. Debido a esto, se consideró incluir la variable `MIGRATE` en el archivo de ambiente, para indicar al contenedor del backend si se requiere o no ejecutar las migraciones. Nota: ya para este repositorio se cuenta con la migración faltante.
- De acuerdo al momento donde se ejecuten las migraciones de la DB, es posible mejorar el tamaño de la imagen del Backend, aprovechando una implementación multicapa muy similar a la del frontend. No se hizo esto debido a que para poder usar `dotnet ef` se requiere el SDK .NET 8 instalado en la imagen.
- Se utilizó un equipo con Ubuntu 24.04 LTS para todas las tareas.
- Se modificó el endpoint de consulta del backend en el frontend de: `https://localhost:7128/Contenedor` por `http://localhost:5198/Contenedor`. Para un entorno productivo se debe usar el https, pero este requiere un certificado SSL.
- Los logs pueden ser consultados con el comando `docker logs -ft --details CONTENEDOR` sustituyendo `CONTENEDOR` por `api`, `frontend` o `sqlserver` de acuerdo al caso.
- Para configurar la persistencia de los datos en el contenedor de SQL Server, debido a que usa un usuario que no es `root` se debe hacer el cambio de propietario al UID `10001` al directorio a almacenar la informacón. En este caso, para el entorno productivo se considerarían mejores prácticas en permisos, usar otro usuario o ejecutar directamente una instancia de SQLServer sin contenedores.

### Healthchecks

#### Backend

El manejo del Healthcheck del backend se hace al endpoint `/Contenedor`, el cual, hace la consulta a la DB para validar que existan los dato.

Se definió directamente en el Dockerfile, con las siguientes características:

- Interval: cada 30 segundos
- Timeout: 10 segundos
- Start-period: 10 segundos
- Comando: `CMD curl -f http://localhost:5198/Contenedor  || exit 1`


#### Frontend

El manejo del Healthcheck del frontend es consultando directamente al puerto `8080`. Si la información fue cargada a la DB, este cargará correctamente la web con la tabla de los contenedores y el contenedor estará `healthy`. 

No se usó otro endpoint ya que se requiere qu funcione el endpoint principal, de lo contrario el stack está fallido.

Se definió directamente en el Dockerfile, con las siguientes características:

- Interval: cada 5 segundos
- Timeout: 10 segundos
- Start-period: 10 segundos
- Comando: `CMD curl -f http://localhost:8080/ || exit 1`

#### SQLServer

El healthcheck se definió a nivel del `docker-compose.yaml`. Se definió para hacer un query a la DB con `SELECT 1`:

- Interval: cada 15 segundos
- Timeout: 10 segundos
- Start-period: 45 segundos
- Start-interval: 30 segundos
- Comando: ```"CMD-SHELL","/opt/mssql-tools18/bin/sqlcmd -U sa -No -S localhost -P `cat $$MSSQL_SA_PASSWORD_FILE` -Q 'SELECT 1'"```

La variable de ambiente `MSSQL_SA_PASSWORD_FILE` especifica la ruta del secret donde se almacena la contraseña del usuario `sa`.


### CI/CD

Se configuró el build automático para los repositorios de `APIContainer` y `Frontend-Contenedores` cuando se realiza un push hacia las ramas `main` o `master` sobre cada repositorio.

Para el caso del despliegue de los contenedores en conjunto mediante `docker-compose.yaml`, se creó un repositorio sobre el cual se intentó hacer las tareas de despliegue, sin éxito.

La idea del mismo es:
- Descargar las imágenes del Docker Hub del front y backend
- Descargar SQLServer
- Arrancar los servicios usando los parámetros de configuración mediante variables de ambiente y secretos.

## Tareas no realizadas
- Rollback simulado
- Notificación
- Pruebas de integración sobre el runner
- Despliegue de distintos ambientes.


## Propuestas

- Notificación: aprovechar los runners y hacer un envío de correo directamente desde alguno, o mediante algún API enviar un mensaje a Telegram, Slack, u otro servicio como Gotify.
- Pruebas de integridad: verificar conexiones como se hacen con los healthcheck