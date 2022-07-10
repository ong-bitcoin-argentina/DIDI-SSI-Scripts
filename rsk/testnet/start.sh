#!/bin/bash

#################################################################################################################################################
#Script para build/ejecución del docker del nodo RSK en la Testnet
#
#	1. Crea las carpetas para los volúmenes del docker-compose (en caso de que no existan) y asigna los permisos pertinentes.
#	2. Inicia el nodo RSK haciendo un "docker-compose up".
#
#	IMPORTANTE: Ejecutar con "sudo".
#################################################################################################################################################

############
#1. Include#
############

#Importa las variables en el archivo "env":
source .env;

##############
#2. Constants#
##############

readonly EXIT_OK=0;	 #Exit Code: OK.

##############
#3. Functions#
##############

#Sale del script si el comando "${@:2}" tiene un exit code ("$1") distinto de "$EXIT_OK".
function exitOnError() {

    exitCode=$1;

    if [ $exitCode -ne $EXIT_OK ]; then

        echo -e "\nLast command failed with code $exitCode.";
        exit $exitCode;
    fi
}

#########
#2. Main#
#########

#rsk_db: Database volume.
if [ ! -d $HOST_RSK_DB_PATH ]; then
  mkdir -p $HOST_RSK_DB_PATH;
  exitOnError $?;
  chown -f 888:888 $HOST_RSK_DB_PATH;
  chmod 775 $HOST_RSK_DB_PATH;
fi

#rsk_cfg: Config files volume.
if [ ! -d $HOST_RSK_CFG_PATH ]; then
  mkdir -p $HOST_RSK_CFG_PATH;
  exitOnError $?;
  chown -f 0:0 $HOST_RSK_CFG_PATH;
  chmod 775 $HOST_RSK_CFG_PATH;
fi

#Build/Run Docker.
docker-compose up -d

exit $?


