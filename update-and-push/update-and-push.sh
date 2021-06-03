#!/bin/bash

###########################################################################################################################################
#"update-and-push.sh"				
###########################################################################################################################################
#
#-Script para actualización de repos de "DIDI/Semillas", y building y push de imágenes Docker.
#-Se generará un tag llamado como la versión utilizada (variable "$DOK_VERSION" en ".env" o parámetro "-v"), el cual apuntará al último commit de "$REPO_BRANCH" (def. en ".env").
#-Clonar repo "DIDI-SSI-Scripts" bajo la misma carpeta raiz donde están los directorios de los repos sobre los que se trabajará.
#-Cambiar los valores "<CHANGE_ME>" del archivo "update-and-push.env.example" y guardar en un nuevo archivo llamado "update-and-push.env".
#-No cambiar este script de lugar.
#-Asegurarse que el path completo que lleva a este script no contenga espacios ni caracteres reservados.
#-Es necesario tener un usuario de GitHub con permisos en los repositorios en los que se trabajará, para el cual se haya generado una clave de autenticación SSH.
#-Posarse sobre la carpeta en la que se encuentra el script desde la consola y ejecutarlo sin "sudo".
#-Se requiere tener instalado:
#
#	-azure:	 apt-get install azure-cli
#	-curl: 	 apt-get install curl
#	-git: 	 apt-get install git
#	-python: apt-get install python
#	-JDK11:  apt install default-jdk
#	-maven:  apt-get install maven
#	-nvm: 	 curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
#
#-Parámetros (opcionales): [ <modulo1> <modulo2> ... <modulon> ] [ -v <ver> -r --push|--upd-only ]
#				
#	<moduloi>:  Módulo a procesar mediante el script.
#	-v <ver>: 	Si se usa este parámetro, se ignorará la versión especificada en la variable de entorno "$DOK_VERSION" y se utilizará "<ver>" en su lugar. 
#	-r:		    Si se usa este parámetro, el script solicitará confirmación del usuario para seguir, luego de haber mostrado el resumen de las operaciones que realizará.
#	--push:     Si se usa este parámetro, se pushearán los Dockers al ACR (por defecto no se pushea).
#	--upd-only:	Si se usa este parámetro, solo se actualizarán los repositorios de los módulos y se instalarán dependencias (no se buildearán/pushearán los Dockers).
#
#	IMPORTANTE-1: "<ver>" no puede empezar con "-".
#	IMPORTANTE-2: No se pueden usar los parámetros "--push" y "--upd-only" a la vez.
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
PROC_MOD="";				  #Array de módulos que serán procesados por el script. Default es "", lo que quiere decir que todos ellos serán procesados.
PROC_CLONE_REPOS=""; 		  #Array que contendrá los repos que serán clonados por el script. Se generará a partir de "$PROC_MOD".
PROC_UPD_REPOS="";			  #Array que contendrá los repos que serán actualizados por el script y para los que se instalarán dependencias. Se generará a partir de "$PROC_MOD".
PROC_DOCKER=""; 			  #Array que contendrá los tags de los Docker que serán buildeados/pusheados por el script. Se generará a partir de "$PROC_MOD".
											
#Posibles parámetros de este script y valores para las distintas posiciones del arreglo "$PROC_MOD":

readonly OPT_MOD_ISSUER_MODULE_BACK="--iss-back"; 	#"didi-issuer-back"
readonly OPT_MOD_ISSUER_MODULE_FRONT="--iss-front"; #"didi-issuer-front".
readonly OPT_MOD_JWT_VALIDATOR_VIEWER="--jwt"; 		#"didi-jwt-validator"
readonly OPT_MOD_MOURO="--mouro"; 					#"didi-mouro".
readonly OPT_MOD_RONDA="--ronda"; 					#"didi-ronda".
readonly OPT_MOD_SEMILLAS_BACK="--sem-be"; 			#"semillas-middleware".
readonly OPT_MOD_SEMILLAS_FRONT="--sem-fe"; 		#"semillas-middleware-frontend".
readonly OPT_MOD_SERVER="--server"; 				#"didi-server".

readonly OPT_VER="-v"; #Parámetro opcional para especificar la versión que se utilizará desde CLI en vez de desde el archivo "update-and-push.env".

readonly OPT_REQ_CONFIRM="-r"; #Parámetro opcional para que el script solicite confirmación por consola para proseguir luego de mostrar el resúmen de las operaciones que efectuará.
REQ_CONFIRM=false; 			   #Variable que dice si hay que solicitar confirmación del usuario. Si no se usa el parámetro "$OPT_REQ_CONFIRM", por defecto no la pide.

readonly OPT_PUSH="--push";    #Parámetro opcional para pushear los Dockers al ACR luego de haberlos buildeado.
PUSH=false;					   #Variable que dice si hay que pushear los Dockers. Si no se usa el parámetro "$OPT_PUSH", por defecto no se pushea.

readonly OPT_UPD_ONLY="--upd-only";	#Parámetro opcional para efectuar únicamente una actualización de los repos de los módulos e instalación de dependencias (sin buildear/pushear).
UPD_ONLY=false;						#Variable que dice si solamente hay que efectuar update de los repos. Si no se usa el parámetro "$OPT_UPD_ONLY", por defecto también se buildea.



##############
#2. Funciones#
##############


#2.1. Nivel 6
#############

#Unset de algunas variables de entorno.
function unsetVars() {

	unset DOK_AZ_USER;
	unset DOK_AZ_PASW;
	unset DOK_VERSION;
}


#2.2. Nivel 5
#############

#Imprime el tiempo de ejecución del script hasta el momento.
function printExecTime() {

	execTime=$SECONDS;
	echo -e "
Tiempo de ejecución: $(($execTime / 60)) min. $(($execTime % 60)) seg.\n";
}

#Hace un unset de algunas variables y sale del script con el exit code "$1".
function exitScript() {

	unsetVars;
	exit $1;
}


#2.3. Nivel 4
#############

#Sale del script si el comando "${@:2}" tiene un exit code ("$1") distinto de "$EXIT_OK".
function exitOnError() {

    exitCode=$1;

    if [ $exitCode -ne $EXIT_OK ]; then

        echo -e "\nEl comando anterior falló con el código $exitCode.";
        printExecTime;
        exitScript $exitCode;
    fi
}


#2.4. Nivel 3
#############

#Cambia a la carpeta "$1", pasa al branch "$REPO_BRANCH", hace un pull, crea el tag "$DOK_VERSION" (si no existe) y hace un push.
function updateRepo() {

	echo -e "
*****************************************************************
Updating/Building \"$1\"				
*****************************************************************\n";	

	#1. Me paro en el repo sobre el que voy a trabajar:
	cd "$1";

	#2. Paso al branch "$REPO_BRANCH":
	git checkout "$REPO_BRANCH";
	exitOnError $?;

	#3. Actualizo el repo local.
	git pull;
	exitOnError $?;

	#4. Creo el tag "$DOK_VERSION" (si no existe):
	if [[ $(git tag -l |grep $DOK_VERSION) == "" ]]; then
		git tag -a "$DOK_VERSION" -m "v$DOK_VERSION";
		exitOnError $?;
	fi

	#5. Pusheo el último commit de "$REPO_BRANCH" al tag:
	echo -e "Pushing to tag \"$DOK_VERSION\"...";
	git push origin "$DOK_VERSION";
	exitOnError $?;
	
	#Agrego el repositorio al arreglo "$alreadyUpdatedRepo", puesto que el mismo se ha actualizado:
	alreadyUpdatedRepo+="$1|";
}

#Instala los paquetes mvn especificados en el repo.
function mvnInstall() {

	mvn package;
	exitOnError $?;
}

#Instala y switchea a la versión requerida de Node.js.
function nvmInstall() {

	nvm install;
	exitOnError $?;
	nvm use;
	exitOnError $?;
}

#Instala yarn y los paquetes npm (mediante yarn) especificados en el repo.
function yarnInstall() {

	npm install --global yarn
	exitOnError $?;
	yarn install --frozen-lockfile
	exitOnError $?;
	yarn run build;
	exitOnError $?;
}

#Instala los paquetes npm especificados en el repo.
function npmInstall() {

	if [ -f "package.json" ]; then
	    npm ci;
	else
		npm i;
	fi

	exitOnError $?;
}

#Buildea el Dockerfile en "$1" con el tag "$2".
function buildDocker() {

	#1. Me paro en la carpeta que contiene el Dockerfile ("$1"):
	cd "$SCRIPT_HOME";
	cd "$1";

	#2. Buildeo el Docker con el tag "$2":
	docker build . -t "$2";
	exitOnError $?;
}


#2.5. Nivel 2
#############

#Devuelve el arreglo "$1", pero sin valores duplicados.
function remDupCols() {

	arr=$(echo "$1" |awk -F "|" 'NR==1{for(i=1;i<=NF;i++)b[$i]++&&a[i]}{for(i in a)$i="";gsub(" +"," ")}1');
	arr=$(echo "$arr" | tr " " "|");

	echo "$arr";
}

#Pregunta por consola si "¿Está seguro de qué desea continuar? (y/n)" y espera confirmación del usuario.
function confirm() {

    read -r -p "¿Está seguro de qué desea continuar? (y/n) " response;
    case "$response" in
        [yY][eE][sS]|[yY]) true;;
        *) false; exitScript $EXIT_UNK;;
    esac
}

#Imprime los valores del arreglo "$1" uno abajo del otro.
function printArr() {

	#Recorro el arreglo "$1":
    let n=$(( $(echo "$1" |awk -F "|" '{print NF}') - 1 ));
    for (( i=1; i<=n; i++ ))
    do
		#Valor de la posición actual de "$1":
        value=$(echo $1 |awk -v ii=$i -F "|" '{print $ii}');

        #Imprimo "$value":
        echo "-$value"
    done
}

#Clona el repo bajo "$REPO_HOME" desde GitHub ("$1").
function cloneOneRepo() {

		echo -e "
*****************************************************************
Cloning \"$value\"				
*****************************************************************\n";	

	    cd "$REPO_HOME";
	    git clone "$1";
	    exitOnError $?;
	    cd "$SCRIPT_HOME";
}

#Cambia al branch "$REPO_BRANCH" del repo "$1", hace un pull, instala dependencias y buildea el Dockerfile en "$2" con el tag "$3".
function updateAndBuildOneRepo() {

	#Se efectúa la actualización e instalación de dependencias en el repo "$1", solo si no se efectuó con anterioridad en esta ejecución del script:
	isRepoUpdated=$(echo "$alreadyUpdatedRepo" |grep "$1");

	if [ "$isRepoUpdated" = "" ]; then
	
		#1. Actualizo el repo "$1":
		updateRepo "$1";

		#2. Instalo dependencias:

		isMvn=$(echo "$MVN_MODULES" |grep "$value");
		isYarn=$(echo "$YARN_MODULES" |grep "$value");
		isNpm=$(echo "$NPM_MODULES" |grep "$value");
		
		#--2.1. Para repos con dependencias "maven":
		if [ "$isMvn" != "" ]; then
			mvnInstall;
		
		#--2.2. Para repos con dependencias "yarn":
		elif [ "$isYarn" != "" ]; then
			nvmInstall;
			yarnInstall;
		
		#--2.3. Para repos con dependencias "npm":
		elif [ "$isNpm" != "" ]; then
			nvmInstall;
			npmInstall;

		fi
	fi

	#3. Buildeo el Dockerfile en "$2" con el tag "$3" (solo si no se utilizó el argumento "$OPT_UPD_ONLY").
	if [ $UPD_ONLY = false ]; then
		buildDocker "$2" "$3";
	fi

	#4. Me paro en la carpeta que contiene este script:
	cd "$SCRIPT_HOME";	
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


#2.6. Nivel 1
#############

#Print de help del script.
function printHelp() {

	echo -e "
*****************************************************************
\"update-and-push.sh\"				
*****************************************************************

-Script para actualización de repos de \"DIDI/Semillas\", y building y push de imágenes Docker.
-Se generará un tag llamado como la versión utilizada (variable \"DOK_VERSION\" en \".env\" o parámetro \"$OPT_VER\"), el cual apuntará al último commit de \"REPO_BRANCH\" (definida en \".env\").
-Clonar repo \"DIDI-SSI-Scripts\" bajo la misma carpeta raiz donde están los directorios de los repos sobre los que se trabajará.
-Cambiar los valores \"<CHANGE_ME>\" del archivo \"update-and-push.env.example\" y guardar en un nuevo archivo llamado \"update-and-push.env\".
-No cambiar este script de lugar.
-Asegurarse que el path completo que lleva a este script no contenga espacios ni caracteres reservados.
-Posarse sobre la carpeta en la que se encuentra el script desde la consola y ejecutarlo sin \"sudo\".
-Se requiere tener instalado:

	-azure: apt-get install azure-cli
	-curl: apt-get install curl
	-git: apt-get install git
	-python: apt-get install python
	-JDK11: apt install default-jdk
	-maven: apt-get install maven
	-nvm: curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash

-Parámetros (opcionales): [ <modulo1> <modulo2> ... <modulon> ] [ $OPT_VER <ver> $OPT_REQ_CONFIRM $OPT_PUSH|$OPT_UPD_ONLY ]
				
	<moduloi>:  Módulo a procesar mediante el script.
	$OPT_VER <ver>: Si se usa este parámetro, se ignorará la versión especificada en la variable de entorno \"DOK_VERSION\" y se utilizará \"<ver>\" en su lugar. 
	$OPT_REQ_CONFIRM: Si se usa este parámetro, el script solicitará confirmación del usuario para seguir, luego de haber mostrado el resumen de las operaciones que realizará.
	$OPT_PUSH: Si se usa este parámetro, se pushearán los Dockers al ACR (por defecto no se pushea).
	$OPT_UPD_ONLY: Si se usa este parámetro, solo se actualizarán los repositorios de los módulos y se instalarán dependencias (no se buildearán/pushearán los Dockers).

	IMPORTANTE-1: \"<ver>\" no puede empezar con \"-\".
	IMPORTANTE-2: No se pueden usar los parámetros \"$OPT_PUSH\" y \"$OPT_UPD_ONLY\" a la vez.

-Módulos (posibles valores de <moduloi>):

	$OPT_MOD_ISSUER_MODULE_BACK: \"didi-issuer-back\"
	$OPT_MOD_ISSUER_MODULE_FRONT: \"didi-issuer-front\".
	$OPT_MOD_JWT_VALIDATOR_VIEWER: \"didi-jwt-validator\".
	$OPT_MOD_MOURO: \"didi-mouro\".
	$OPT_MOD_RONDA: \"didi-ronda\".
	$OPT_MOD_SEMILLAS_BACK: \"semillas-middleware\".
	$OPT_MOD_SEMILLAS_FRONT: \"semillas-middleware-frontend\".
	$OPT_MOD_SERVER: \"didi-server\".

IMPORTANTE: Si se repiten módulos en los parámetros, el script los procesará una única vez.\n";

	exitScript $EXIT_UNK;
}

#Se remueven parámetros duplicados del arreglo "$PROC_MOD". Además, en caso de que el script se haya ejecutado sin parámetros, se agrega la totalidad de los módulos a "$PROC_MOD".
function procModTweak() {

	#1. Remoción de duplicados:
	PROC_MOD=$(remDupCols "$PROC_MOD");

	#2. Agregado de módulos:
	if [ "$PROC_MOD" = "" ]; then 
		PROC_MOD="$DOK_FILE_ISSUER_MODULE_BACK|$DOK_FILE_ISSUER_MODULE_FRONT|$DOK_FILE_JWT_VALIDATOR_VIEWER|$DOK_FILE_MOURO|$DOK_FILE_RONDA|$DOK_FILE_SEMILLAS_BACK|$DOK_FILE_SEMILLAS_FRONT|$DOK_FILE_SERVER|";
	fi
}

#A. Obtiene los repos que serán clonados por el script en "$PROC_CLONE_REPOS" a partir de 
#B. Obtiene los repos que serán actualizados por el script y para los que se instalarán dependencias en "$PROC_UPD_REPOS" a partir de "$PROC_MOD".
function getReposToCloneUpd() {

	#Recorro el arreglo "$PROC_MOD":
    let n=$(( $(echo "$PROC_MOD" |awk -F "|" '{print NF}') - 1 ));
    for (( i=1; i<=n; i++ ))
    do
		#Valor de la posición actual de "$PROC_MOD":
        value=$(echo $PROC_MOD |awk -v ii=$i -F "|" '{print $ii}');

        #Cantidad de carpetas en path "$REPO_HOME":
    	let repoHomeLenght=$(echo "$REPO_HOME" |awk -F "/" '{print NF}');
   	
    	#Carpeta específica del repo dentro del path "$value":
    	repoFolder=$(echo $value |awk -v ii=$(( $repoHomeLenght + 1 )) -F "/" '{print $ii}');

    	#Agrego el repo a "$PROC_UPD_REPOS":
    	PROC_UPD_REPOS+="$REPO_HOME/$repoFolder|";

        #Si el repo no existe localmente, entonces agregarlo a "$PROC_CLONE_REPOS":
        if [ ! -d "$value" ]; then
        	PROC_CLONE_REPOS+="$REPO_HOME/$repoFolder|";
        fi
    done

    #Elimino valores repetidos de "$PROC_CLONE_REPOS" y "$PROC_UPD_REPOS":
    PROC_CLONE_REPOS=$(remDupCols "$PROC_CLONE_REPOS");
    PROC_UPD_REPOS=$(remDupCols "$PROC_UPD_REPOS");
}

#Obtiene los tags de los Dockers que serán buildeados/pusheados por el script en "$PROC_DOCKER" a partir de "$PROC_MOD".
function getDocktoProc() {

	#Recorro el arreglo "$PROC_MOD":
    let n=$(( $(echo "$PROC_MOD" |awk -F "|" '{print NF}') - 1 ));
    for (( i=1; i<=n; i++ ))
    do
		#Valor de la posición actual de "$PROC_MOD":
        value=$(echo $PROC_MOD |awk -v ii=$i -F "|" '{print $ii}');

       #Agrego el docker tag de cada módulo a "$PROC_DOCKER":
		case "$value" in
			"$DOK_FILE_ISSUER_MODULE_BACK") PROC_DOCKER+="$DOK_TAG_ISSUER_MODULE_BACK|";; 
			"$DOK_FILE_ISSUER_MODULE_FRONT") PROC_DOCKER+="$DOK_TAG_ISSUER_MODULE_FRONT|";;
			"$DOK_FILE_JWT_VALIDATOR_VIEWER") PROC_DOCKER+="$DOK_TAG_JWT_VALIDATOR_VIEWER|";;
			"$DOK_FILE_MOURO") PROC_DOCKER+="$DOK_TAG_MOURO|";;
			"$DOK_FILE_RONDA") PROC_DOCKER+="$DOK_TAG_RONDA|";;
			"$DOK_FILE_SEMILLAS_BACK") PROC_DOCKER+="$DOK_TAG_SEMILLAS_BACK|";;
			"$DOK_FILE_SEMILLAS_FRONT") PROC_DOCKER+="$DOK_TAG_SEMILLAS_FRONT|";;
			"$DOK_FILE_SERVER") PROC_DOCKER+="$DOK_TAG_SERVER|";;
		esac
	done
}

#Imprime un resumen de las operaciones que efectuará el script:
#
#	-Repos a clonar.
#	-Dockers a buildear/pushear.
function printSumm() {

	echo -e "
*****************************************************************
Resumen de Operaciones:				
*****************************************************************\n";

	#1. Imprimo el branch/tag sobre el que se trabajará:
	echo -e "1. Se pusheará el último commit del branch \"$REPO_BRANCH\" al tag \"$DOK_VERSION\"."

	#2. Imprimo repos a clonar:
	if [ "$PROC_CLONE_REPOS" != "" ]; then
		echo -e "\n2. Se clonarán los siguientes repositorios:\n";
		printArr "$PROC_CLONE_REPOS";

	else
		echo -e "\n2. No se clonará ningún repositorio!";
	fi

	#3. Imprimo repos a actualizar:
	echo -e "\n3. Se actualizarán y se instalarán dependencias para los siguientes repositorios:\n";
	printArr "$PROC_UPD_REPOS";

	#4. Imprimo Dockers a buildear/pushear (solo si no se utilizó el argumento "$OPT_UPD_ONLY"):
	if [ $UPD_ONLY = false ]; then
		if [ $PUSH = true ]; then
			echo -e "\n4. Se buildearán/pushearán los siguientes Docker:\n";
		else
			echo -e "\n4. Se buildearán (no se pushearán!) los siguientes Docker:\n";
		fi

		printArr "$PROC_DOCKER";

	else
		echo -e "\n4. No se buildeará/pusheará ningún Docker!\n";
	fi

	echo -e "
*****************************************************************\n";

	#Si el script fue ejecutado con el parámetro "$OPT_REQ_CONFIRM", se pregunta al usuario si quiere continuar:
	if [ $REQ_CONFIRM = true ]; then
		confirm;

	fi
}

#Para cada repo en "$PROC_CLONE_REPOS":
#
#	-Clona el repo correspondiente desde GitHub bajo el directorio "$REPO_HOME".
function clone() {

	#Recorro el arreglo "$PROC_CLONE_REPOS":
    let n=$(( $(echo "$PROC_CLONE_REPOS" |awk -F "|" '{print NF}') - 1 ));
    for (( i=1; i<=n; i++ ))
    do
		#Valor de la posición actual de "$PROC_CLONE_REPOS":
        value=$(echo $PROC_CLONE_REPOS |awk -v ii=$i -F "|" '{print $ii}');

		#Clone del repo "$value":
		case "$value" in
			"$REPO_ISSUER_MODULE_BACK") cloneOneRepo "$GITHUB_ISSUER_MODULE_BACK";; 
			"$REPO_ISSUER_MODULE_FRONT") cloneOneRepo "$GITHUB_ISSUER_MODULE_FRONT";;
			"$REPO_JWT_VALIDATOR_VIEWER") cloneOneRepo "$GITHUB_JWT_VALIDATOR_VIEWER";;
			"$REPO_MOURO") cloneOneRepo "$GITHUB_MOURO";;
			"$REPO_RONDA") cloneOneRepo "$GITHUB_RONDA";;
			"$REPO_SEMILLAS_BACK") cloneOneRepo "$GITHUB_SEMILLAS_BACK";;
			"$REPO_SEMILLAS_FRONT") cloneOneRepo "$GITHUB_SEMILLAS_FRONT";;
			"$REPO_SERVER") cloneOneRepo "$GITHUB_SERVER";;
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
			"$DOK_FILE_ISSUER_MODULE_BACK") updateAndBuildOneRepo "$REPO_ISSUER_MODULE_BACK" "$DOK_FILE_ISSUER_MODULE_BACK" "$DOK_TAG_ISSUER_MODULE_BACK";; 
			"$DOK_FILE_ISSUER_MODULE_FRONT") updateAndBuildOneRepo "$REPO_ISSUER_MODULE_FRONT" "$DOK_FILE_ISSUER_MODULE_FRONT" "$DOK_TAG_ISSUER_MODULE_FRONT";;
			"$DOK_FILE_JWT_VALIDATOR_VIEWER") updateAndBuildOneRepo "$REPO_JWT_VALIDATOR_VIEWER" "$DOK_FILE_JWT_VALIDATOR_VIEWER" "$DOK_TAG_JWT_VALIDATOR_VIEWER";;
			"$DOK_FILE_MOURO") updateAndBuildOneRepo "$REPO_MOURO" "$DOK_FILE_MOURO" "$DOK_TAG_MOURO";;
			"$DOK_FILE_RONDA") updateAndBuildOneRepo "$REPO_RONDA" "$DOK_FILE_RONDA" "$DOK_TAG_RONDA";;
			"$DOK_FILE_SEMILLAS_BACK") updateAndBuildOneRepo "$REPO_SEMILLAS_BACK" "$DOK_FILE_SEMILLAS_BACK" "$DOK_TAG_SEMILLAS_BACK";;
			"$DOK_FILE_SEMILLAS_FRONT") updateAndBuildOneRepo "$REPO_SEMILLAS_FRONT" "$DOK_FILE_SEMILLAS_FRONT" "$DOK_TAG_SEMILLAS_FRONT";;
			"$DOK_FILE_SERVER") updateAndBuildOneRepo "$REPO_SERVER" "$DOK_FILE_SERVER" "$DOK_TAG_SERVER";;
		esac
	done
}

#Para cada docker en "$PROC_DOCKER":
#
#	-Pushea el Docker buildeado al ACR.
function push() {

	if [ $PUSH = true ] && [ $UPD_ONLY = false ]; then
	
		#Login a la consola de Azure:
		az acr login --name "$DOK_AZ_NAME" --user "$DOK_AZ_USER" --password "$DOK_AZ_PASW";
		exitOnError $?;
		
		#Recorro el arreglo "$PROC_DOCKER":
		let n=$(( $(echo "$PROC_DOCKER" |awk -F "|" '{print NF}') - 1 ));
		for (( i=1; i<=n; i++ ))
		do
			#Valor de la posición actual de "$PROC_DOCKER":
			value=$(echo $PROC_DOCKER |awk -v ii=$i -F "|" '{print $ii}');

			#Push del Docker "$value":
			pushOneDocker "$value";
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
        "$OPT_MOD_ISSUER_MODULE_BACK") PROC_MOD+="$DOK_FILE_ISSUER_MODULE_BACK|";; 
        "$OPT_MOD_ISSUER_MODULE_FRONT") PROC_MOD+="$DOK_FILE_ISSUER_MODULE_FRONT|";;
        "$OPT_MOD_JWT_VALIDATOR_VIEWER") PROC_MOD+="$DOK_FILE_JWT_VALIDATOR_VIEWER|";;
        "$OPT_MOD_MOURO") PROC_MOD+="$DOK_FILE_MOURO|";;
        "$OPT_MOD_RONDA") PROC_MOD+="$DOK_FILE_RONDA|";;
		"$OPT_MOD_SEMILLAS_BACK") PROC_MOD+="$DOK_FILE_SEMILLAS_BACK|";;
		"$OPT_MOD_SEMILLAS_FRONT") PROC_MOD+="$DOK_FILE_SEMILLAS_FRONT|";;
		"$OPT_MOD_SERVER") PROC_MOD+="$DOK_FILE_SERVER|";;
		"$OPT_VER") shift; DOK_VERSION="$1"; source update-and-push.env;;
		"$OPT_REQ_CONFIRM") REQ_CONFIRM=true;;
		"$OPT_PUSH") PUSH=true;;
		"$OPT_UPD_ONLY") UPD_ONLY=true;;
        *) printHelp; #Si se ingresa cualquier otro parámetro imprimir ayuda.
    esac
    shift
done

#Si se utilizaron los parámetros "$OPT_PUSH" y "$OPT_UPD_ONLY" a la vez, mostrar help y abortar la ejecución del script.
if [ $PUSH = true ] && [ $UPD_ONLY = true ]; then
	echo -e "\nNo se pueden utilizar los parámetros \"$OPT_PUSH\" y \"$OPT_UPD_ONLY\" a la vez!";
	printHelp;
fi 

#Si se utilizó una versión con un "-" al principio (ya sea desde CLI o desde "update-and-push.env"), mostrar help y abortar la ejecución del script.
if [[ $DOK_VERSION == -* ]]; then
	echo -e "\nNo se puede utilizar una versión que comience con \"-\"! (si no se está especificando por CLI, revisar valor de variable \"DOK_VERSION\")";
	printHelp;
fi 

#Tweaking de "$PROC_MOD".
procModTweak;


#3.2. Resumen de operaciones
############################

#3.2.1. Repos a clonar:
getReposToCloneUpd;

#3.2.2. Dockers a buildear/pushear:
getDocktoProc;

#3.2.3. Imprimir resumen
printSumm;

#Cantidad de segundos que pasaron desde que comenzó la ejecución del script en 0.
SECONDS=0;


#3.3. Update, Build & Push
##########################

#3.3.1. Clone:
clone;

#3.3.2. Update and Build:
updateAndBuild;
	
#3.3.3. Push:
push;


#3.4. Exit
##########

echo -e "\nEl script ha finalizado con éxito! (:";
printExecTime;
exitScript $EXIT_OK;


