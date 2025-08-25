#!/bin/sh

if [ "$1" == "migrar" ]
    then
        echo "Cargar migraciones"
        dotnet ef database update --project /src
        if [ $? -eq 1 ]
            then
                echo "Error en ejecución. Salir."
                return 1
        fi
fi

/publish/APIContainers