#!/bin/bash

###########################################################################################################################################
#"update-and-push.sh"				
###########################################################################################################################################
#
#-Script para actualización de repos de "DIDI/Semillas", y building y push de imágenes Docker.
#-Clonar repo "DIDI-SSI-Scripts" bajo la misma carpeta raiz donde están los directorios de los repos sobre los que se trabajará.
#-Cambiar los valores "<CHANGE_ME>" del archivo "update-and-push.env.example" y guardar en un nuevo archivo llamado "update-and-push.env".
#-No cambiar este script de lugar.
#-Asegurarse que el path completo que lleva a este script no contenga espacios ni caracteres reservados.
#-Es necesario tener un usuario de GitHub con permisos en los repositorios en los que se trabajará, para el cual se haya generado una clave de autenticación SSH.
#-Posarse sobre la carpeta en la que se encuentra el script desde la consola y ejecutarlo sin "sudo".
#-Se requiere tener instalado:
#
#	-curl: apt-get install curl
#	-git: apt-get install git
#	-python: apt-get install python
#	-JDK11: apt install default-jdk
#	-maven: apt-get install maven
#	-nvm: curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
#
#-Parámetros (opcionales): [ <modulo1> <modulo2> ... <modulon> ] [ --dont-push ]
#				
#	<moduloi>: 	 Módulo a procesar mediante el script.
#	--dont-push: Si se usa este parámetro, no se pushearán los Dockers al ACR.
#				
#-Módulos (posibles valores de <moduloi>):
#
#	--iss-back:  "didi-issuer-back"
#	--iss-front: "didi-issuer-front".
#	--jwt: 	   	 "didi-jwt-validator".
#	--mouro:	 "didi-mouro".
#	--ronda: 	 "didi-ronda".
#	--sem-be:    "semillas-middleware".
#	--sem-fe:    "semillas-middleware-frontend".
#	--server:    "didi-server".
#
#	IMPORTANTE: Si se repiten módulos en los parámetros, el script los procesará una única vez.
###########################################################################################################################################



###########
#1. Global#
###########


#1.1. Includes
##############

chmod +x update-and-push.env;
source update-and-push.env;


#1.2. Variables
###############

#1.2.1. Exit Codes
readonly EXIT_OK=0;	 #Exit Code: OK.
readonly EXIT_UNK=1; #Exit Code: Unknown.

#1.2.2. nvm
export NVM_DIR=$HOME/.nvm;
source $NVM_DIR/nvm.sh;

#1.2.3. Parámetros
PROC_MOD="";										#Array de módulos que serán procesados por el script. 
													#Default es "", lo que quiere decir que todos ellos serán procesados.
											
#Posibles parámetros de este script y valores para las distintas posiciones del arreglo "$PROC_MOD":

readonly OPT_MOD_ISSUER_MODULE_BACK="--iss-back"; 	#"didi-issuer-back"
readonly OPT_MOD_ISSUER_MODULE_FRONT="--iss-front"; #"didi-issuer-front".
readonly OPT_MOD_JWT_VALIDATOR_VIEWER="--jwt"; 		#"didi-jwt-validator"
readonly OPT_MOD_MOURO="--mouro"; 					#"didi-mouro".
readonly OPT_MOD_RONDA="--ronda"; 					#"didi-ronda".
readonly OPT_MOD_SEMILLAS_BACK="--sem-be"; 			#"semillas-middleware".
readonly OPT_MOD_SEMILLAS_FRONT="--sem-fe"; 		#"semillas-middleware-frontend".
readonly OPT_MOD_FILE_SERVER="--server"; 			#"didi-server".

readonly OPT_DONT_PUSH="--dont-push";				#Parámetro opcional que evita pushear los Dockers luego de haberlos buildeado.
DONT_PUSH=false;									#Variable que dice si hay que pushear los Dockers. Si no se usa el parámetro "$OPT_DONT_PUSH",			 
													#por defecto se pushea.



##############
#2. Funciones#
##############


#Unset de algunas variables de entorno.
function unsetVars() {

	unset DOK_AZ_USER;
	unset DOK_AZ_PASW;
}

#Print de help del script.
function printHelp() {

	echo -e "
*****************************************************************
\"update-and-push.sh\"				
*****************************************************************

-Script para actualización de repos de \"DIDI/Semillas\", y building y push de imágenes Docker.
-Clonar repo \"DIDI-SSI-Scripts\" bajo la misma carpeta raiz donde están los directorios de los repos sobre los que se trabajará.
-Cambiar los valores \"<CHANGE_ME>\" del archivo \"update-and-push.env.example\" y guardar en un nuevo archivo llamado \"update-and-push.env\".
-No cambiar este script de lugar.
-Asegurarse que el path completo que lleva a este script no contenga espacios ni caracteres reservados.
-Posarse sobre la carpeta en la que se encuentra el script desde la consola y ejecutarlo sin \"sudo\".
-Se requiere tener instalado:

	-curl: apt-get install curl
	-git: apt-get install git
	-python: apt-get install python
	-JDK11: apt install default-jdk
	-maven: apt-get install maven
	-nvm: curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash

-Parámetros (opcionales): [ <modulo1> <modulo2> ... <modulon> ] [ $OPT_DONT_PUSH ]
				
	<moduloi>: Módulo a procesar mediante el script.
	$OPT_DONT_PUSH: Si se usa este parámetro, no se pushearán los Dockers al ACR.
				
-Módulos (posibles valores de <moduloi>):

	$OPT_MOD_ISSUER_MODULE_BACK: \"didi-issuer-back\"
	$OPT_MOD_ISSUER_MODULE_FRONT: \"didi-issuer-front\".
	$OPT_MOD_JWT_VALIDATOR_VIEWER: \"didi-jwt-validator\".
	$OPT_MOD_MOURO: \"didi-mouro\".
	$OPT_MOD_RONDA: \"didi-ronda\".
	$OPT_MOD_SEMILLAS_BACK: \"semillas-middleware\".
	$OPT_MOD_SEMILLAS_FRONT: \"semillas-middleware-frontend\".
	$OPT_MOD_FILE_SERVER: \"didi-server\".

	IMPORTANTE: Si se repiten módulos en los parámetros, el script los procesará una única vez.\n";
	
	unsetVars;
	
	exit $EXIT_UNK;
}

#Elimina los valores duplicados del arreglo "$PROC_MOD".
function remDupCols() {

	PROC_MOD=$(echo "$PROC_MOD" |awk -F "|" 'NR==1{for(i=1;i<=NF;i++)b[$i]++&&a[i]}{for(i in a)$i="";gsub(" +"," ")}1');
	PROC_MOD=$(echo "$PROC_MOD" | tr " " "|");	
}

#Se remueven parámetros duplicados del arreglo "$PROC_MOD". Además, en caso de que el script se haya ejecutado sin parámetros, se agrega la totalidad de los módulos a "$PROC_MOD".
function procModTweak() {

	#1. Remoción de duplicados:
	remDupCols;

	#2. Agregado de módulos:
	if [ "$PROC_MOD" = "" ]; then 
		PROC_MOD="$OPT_MOD_ISSUER_MODULE_BACK|$OPT_MOD_ISSUER_MODULE_FRONT|$OPT_MOD_JWT_VALIDATOR_VIEWER|$OPT_MOD_MOURO|$OPT_MOD_RONDA|$OPT_MOD_SEMILLAS_BACK|$OPT_MOD_SEMILLAS_FRONT|$OPT_MOD_FILE_SERVER|"
	fi
}

#Sale del script si el comando "${@:2}" tiene un exitCode ("$1") distinto de "$EXIT_OK".
function exitOnError() {

    exitCode=$1;

    if [ $exitCode -ne $EXIT_OK ]; then

        echo -e "\nEl comando anterior falló con el código $exitCode.";
        exit $exitCode;
    fi
}

#Clona el repo "$1" desde GitHub ("$2") en caso de que no exista con anterioridad.
function cloneOneRepo() {

	if [ ! -d "$1" ]; then

		echo -e "
*****************************************************************
Cloning \"$1\"				
*****************************************************************\n";	

	    cd "$REPO_HOME";
	    git clone "$2";
	    exitOnError $?;
	    cd "$SCRIPT_HOME";
	fi
}

#Cambia a la carpeta "$1", pasa al branch "develop" y hace un pull.
function updateRepo() {

	echo -e "
*****************************************************************
Updating/Building \"$1\"				
*****************************************************************\n";	

	cd "$1";
	git checkout "$REPO_BRANCH";
	exitOnError $?;
	git pull;
	exitOnError $?;
	
	#Agrego el repositorio al arreglo "$alreadyUpdatedRepo", puesto que el mismo se ha actualizado:
	alreadyUpdatedRepo+="$1|";
}

#Buildea el Dockerfile en "$1" con el tag "$2".
function buildDocker() {

	#1. Me paro en la carpeta que contiene el Dockerfile ("$1"):
	cd "$SCRIPT_HOME";
	cd "$1";

	#2. Buildeo el Docker con el tag "$2":
	docker build . -t "$2";
	exitOnError $?;

	#3. Me paro en la carpeta que contiene este script:
	cd "$SCRIPT_HOME";	
}

#Instala y switchea a la versión requerida de Node.js.
function nvmInstall() {

	nvm install;
	exitOnError $?;
	nvm use;
	exitOnError $?;
}

#Cambia al branch "$REPO_BRANCH" del repo "$1", hace un pull, instala dependencias y buildea el Dockerfile en "$2" con el tag "$3".
function updateAndBuildOneRepo() {

	#Se efectúa la actualización e instalación de dependencias en el repo "$1", solo si no se efectuó con anterioridad en esta ejecución del script:
	isRepoUpdated=$(echo "$alreadyUpdatedRepo" |grep "$1");

	if [ "$isRepoUpdated" = "" ]; then
	
		#1. Actualizo el repo "$1":
		updateRepo "$1";

		#2. Instalo dependencias:
		
		#--2.1. Para "semillas-middleware" (Semillas Backend):
		if [ "$value" = "$OPT_MOD_SEMILLAS_BACK" ]; then
			mvn package;
			exitOnError $?;
		
		#--2.2. Para "semillas-middleware-frontend" (Semillas Frontend):
		elif [ "$value" = "$OPT_MOD_SEMILLAS_FRONT" ]; then
			nvmInstall;
			npm install --global yarn
			exitOnError $?;
			yarn;
			exitOnError $?;
			yarn run build;
			exitOnError $?;
		
		#--2.3. Para el resto de los módulos (excepto "didi-jwt-validator"):
		elif [ "$value" != "$OPT_MOD_JWT_VALIDATOR_VIEWER" ]; then
			nvmInstall;
			npm i;
			exitOnError $?;

		fi
	fi

	#3. Buildeo el Dockerfile en "$2" con el tag "$3".
	buildDocker "$2" "$3";
}

#Pushea el Docker "$1".
function pushOneDocker() {

	echo -e "
*****************************************************************
Pushing \"$1\"				
*****************************************************************\n";	

	docker push "$1";
	exitOnError $?;
}

#Para cada módulo en "$PROC_MOD":
#
#	-Clona el repo correspondiente desde GitHub bajo el directorio "$REPO_HOME".
clone() {

    let n=$(( $(echo "$PROC_MOD" |awk -F "|" '{print NF}') - 1 ));
    for (( i=1; i<=n; i++ ))
    do
		#Valor de la posición actual de "$PROC_MOD":
        value=$(echo $PROC_MOD |awk -v ii=$i -F "|" '{print $ii}');
		
		#Clone del repo para el módulo "$value":
		case "$value" in
			"$OPT_MOD_ISSUER_MODULE_BACK") cloneOneRepo "$REPO_ISSUER_MODULE_BACK" "$GITHUB_ISSUER_MODULE_BACK";; 
			"$OPT_MOD_ISSUER_MODULE_FRONT") cloneOneRepo "$REPO_ISSUER_MODULE_FRONT" "$GITHUB_ISSUER_MODULE_FRONT";;
			"$OPT_MOD_JWT_VALIDATOR_VIEWER") cloneOneRepo "$REPO_JWT_VALIDATOR_VIEWER" "$GITHUB_JWT_VALIDATOR_VIEWER";;
			"$OPT_MOD_MOURO") cloneOneRepo "$REPO_MOURO" "$GITHUB_MOURO";;
			"$OPT_MOD_RONDA") cloneOneRepo "$REPO_RONDA" "$GITHUB_RONDA";;
			"$OPT_MOD_SEMILLAS_BACK") cloneOneRepo "$REPO_SEMILLAS_BACK" "$GITHUB_SEMILLAS_BACK";;
			"$OPT_MOD_SEMILLAS_FRONT") cloneOneRepo "$REPO_SEMILLAS_FRONT" "$GITHUB_SEMILLAS_FRONT";;
			"$OPT_MOD_FILE_SERVER") cloneOneRepo "$REPO_SERVER" "$GITHUB_SERVER";;
		esac
	done
}

#Para cada módulo en "$PROC_MOD":
#
#	-Actualiza el repo correspondiente en la rama  "$REPO_BRANCH"
#	-Instala dependencias.
#	-Buildea Dockerfiles.
function updateAndBuild() {

	#Arreglo que contiene repos que se han actualizado y que tienen las dependencias instaladas:
	alreadyUpdatedRepo="";

	#Recorro el arreglo "$PROC_MOD":
    let n=$(( $(echo "$PROC_MOD" |awk -F "|" '{print NF}') - 1 ));
    for (( i=1; i<=n; i++ ))
    do
		#Valor de la posición actual de "$PROC_MOD":
        value=$(echo $PROC_MOD |awk -v ii=$i -F "|" '{print $ii}');
		
		#Update & Build del módulo "$value":
		case "$value" in
			"$OPT_MOD_ISSUER_MODULE_BACK") updateAndBuildOneRepo "$REPO_ISSUER_MODULE_BACK" "$DOK_FILE_ISSUER_MODULE_BACK" "$DOK_TAG_ISSUER_MODULE_BACK";; 
			"$OPT_MOD_ISSUER_MODULE_FRONT") updateAndBuildOneRepo "$REPO_ISSUER_MODULE_FRONT" "$DOK_FILE_ISSUER_MODULE_FRONT" "$DOK_TAG_ISSUER_MODULE_FRONT";;
			"$OPT_MOD_JWT_VALIDATOR_VIEWER") updateAndBuildOneRepo "$REPO_JWT_VALIDATOR_VIEWER" "$DOK_FILE_JWT_VALIDATOR_VIEWER" "$DOK_TAG_JWT_VALIDATOR_VIEWER";;
			"$OPT_MOD_MOURO") updateAndBuildOneRepo "$REPO_MOURO" "$DOK_FILE_MOURO" "$DOK_TAG_MOURO";;
			"$OPT_MOD_RONDA") updateAndBuildOneRepo "$REPO_RONDA" "$DOK_FILE_RONDA" "$DOK_TAG_RONDA";;
			"$OPT_MOD_SEMILLAS_BACK") updateAndBuildOneRepo "$REPO_SEMILLAS_BACK" "$DOK_FILE_SEMILLAS_BACK" "$DOK_TAG_SEMILLAS_BACK";;
			"$OPT_MOD_SEMILLAS_FRONT") updateAndBuildOneRepo "$REPO_SEMILLAS_FRONT" "$DOK_FILE_SEMILLAS_FRONT" "$DOK_TAG_SEMILLAS_FRONT";;
			"$OPT_MOD_FILE_SERVER") updateAndBuildOneRepo "$REPO_SERVER" "$DOK_FILE_SERVER" "$DOK_TAG_SERVER";;
		esac
	done
}

#Para cada módulo en "$PROC_MOD":
#
#	-Pushea el Docker buildeado al ACR.
function push() {

	if [ $DONT_PUSH = false ]; then
	
		#Login a la consola de Azure:
		az acr login --name "$DOK_AZ_NAME" --user "$DOK_AZ_USER" --password "$DOK_AZ_PASW";
		exitOnError $?;
		
		#Recorro el arreglo "$PROC_MOD":
		let n=$(( $(echo "$PROC_MOD" |awk -F "|" '{print NF}') - 1 ));
		for (( i=1; i<=n; i++ ))
		do
			#Valor de la posición actual de "$PROC_MOD":
			value=$(echo $PROC_MOD |awk -v ii=$i -F "|" '{print $ii}');
			
			#Push del Docker para el módulo "$value":
			case "$value" in
				"$OPT_MOD_ISSUER_MODULE_BACK") pushOneDocker "$DOK_TAG_ISSUER_MODULE_BACK";; 
				"$OPT_MOD_ISSUER_MODULE_FRONT") pushOneDocker "$DOK_TAG_ISSUER_MODULE_FRONT";;
				"$OPT_MOD_JWT_VALIDATOR_VIEWER") pushOneDocker "$DOK_TAG_JWT_VALIDATOR_VIEWER";;
				"$OPT_MOD_MOURO") pushOneDocker "$DOK_TAG_MOURO";;
				"$OPT_MOD_RONDA") pushOneDocker "$DOK_TAG_RONDA";;
				"$OPT_MOD_SEMILLAS_BACK") pushOneDocker "$DOK_TAG_SEMILLAS_BACK";;
				"$OPT_MOD_SEMILLAS_FRONT") pushOneDocker "$DOK_TAG_SEMILLAS_FRONT";;
				"$OPT_MOD_FILE_SERVER") pushOneDocker "$DOK_TAG_SERVER";;
			esac
		done	
		
		#Logout a la consola de Azure:
		az logout --username="$DOK_AZ_USER";
	
	fi
}



#########
#3. Main#
#########


#3.1. Tratamiento de parámetros
###############################

while [ $# -gt 0 ]; do
    case $1 in
        "$OPT_MOD_ISSUER_MODULE_BACK") PROC_MOD+="$1|";; 
        "$OPT_MOD_ISSUER_MODULE_FRONT") PROC_MOD+="$1|";;
        "$OPT_MOD_JWT_VALIDATOR_VIEWER") PROC_MOD+="$1|";;
        "$OPT_MOD_MOURO") PROC_MOD+="$1|";;
        "$OPT_MOD_RONDA") PROC_MOD+="$1|";;
		"$OPT_MOD_SEMILLAS_BACK") PROC_MOD+="$1|";;
		"$OPT_MOD_SEMILLAS_FRONT") PROC_MOD+="$1|";;
		"$OPT_MOD_FILE_SERVER") PROC_MOD+="$1|";;
		"$OPT_DONT_PUSH") DONT_PUSH=true;;
        *) printHelp; #Si se ingresa cualquier otro parámetro imprimir ayuda.
    esac
    shift
done

#Tweaking de "$PROC_MOD".
procModTweak;


#3.2. Update, Build & Push
##########################

#3.2.1. Clone:
clone;

#3.2.2. Update and Build:
updateAndBuild;
	
#3.2.3. Push:
push;


#3.3. Exit
##########

#3.3.1. Unset de variables de entorno con datos sensibles:
unsetVars;

#3.3.2. Exit:
echo -e "\nEl script ha finalizado con éxito! (:";
exit $EXIT_OK;


