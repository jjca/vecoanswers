# Entregables

## API

Se despliega usando la imagen definida en el Dockerfile dentro del repositorio de APIContainer.

## Frontend

Se despliega usando la imagen definida en el Dockerfile dentro del repositorio de Frontend-Contenedores.

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
6. Ejecutar `docker compose up`.

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

Nombre de la base de datos sobre la cual trabajar

## Secretos

### appsettings.json

Incluye la configuración de conexión hacia la base de datos.

### db_password

## Detalles técnicos

- Se observó que era requerido crear una nueva migración. Debido a esto, se consideró incluir la variable `MIGRATE` en el archivo de ambiente, para indicar al contenedor del backend si se requiere o no ejecutar las migraciones. Nota: ya para este repositorio se cuenta con la migración faltante.
- El manejo del Healthcheck del backend se hace aprovechando el endpoint `/WeatherForecast`. Esto no significa que el servicio funcione correctamente.
- El manejo del Healthcheck del frontend es consultando directamente al puerto `8080`. Si la información fue cargada a la DB, este cargará correctamente la web y el contenedor estará `healthy`.
- De acuerdo al momento donde se ejecuten las migraciones de la DB, es posible mejorar el tamaño de la imagen del Backend, aprovechando una implementación multicapa muy similar a la del frontend. No se hizo esto debido a que para poder usar `dotnet ef` se requiere el SDK .NET 8 instalado en la imagen.
- Se utilizó un equipo con Ubuntu 24.04 LTS para todas las tareas.
- Se modificó el endpoint de consulta del backend en el frontend de: `https://localhost:7128/Contenedor` por `http://localhost:5198/Contenedor`
- Los logs pueden ser consultados con el comando `docker logs -ft --details CONTENEDOR` sustituyendo `CONTENEDOR` por `api`, `frontend` o `sqlserver` de acuerdo al caso.