# DIDI-SSI-Scripts

# 1. Summary

This guide explains how to use different scripts in this repo.

# 2. Scripts

## 2.1. update-and-push

- Script for repo updating of *DIDI/Semillas*, tag creation and Docker image building/pushing. 
- Clone repo *DIDI-SSI-Scripts* in the same folder where the other *ong-bitcoin-argentina* repos are.
- Change *<CHANGE_ME>*  values in *update-and-push.env.example* and save changes in a new file named *update-and-push.env*.
- Don't change the folder where this script lives.
- Double check that the full path to this script in your local computer doesn't contain spaces nor reserved characters.
- Use your Linux console to go to local folder where this scripts lives and run it (not as *sudo*).

### 2.1.1. Dependencies

- *azure*: `sudo apt-get install azure-cli`
- *build-essential*: `sudo apt-get install build-essential`
- *curl*: `sudo apt-get install curl`
- *git*: `sudo apt-get install git`
- *docker*:  https://docs.docker.com/engine/install/ubuntu/
- *python*: `sudo apt-get install python`
- *JDK11*: `sudo apt install default-jdk`
- *maven*: `sudo apt-get install maven`
- *nvm*: `curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash && source ~/.profile`

**IMPORTANT:** `docker` must be accessible using the non-root user which will run this script without using `sudo`. For doing that see **Manage Docker as a non-root user** on this link: https://docs.docker.com/engine/install/linux-postinstall/

### 2.1.2. Parameters

A. Optional parameters:

`[ <module1> <module2> ... <moduloe> ] [ -v <ver> -r --upd-only|--push ]`
		
- `<modulei>`: Module to be processed with this script.
- `-v <ver>`: If you use this parameter, variable `$DOK_VERSION` will be ignored and `<ver` will be used in its place. 
- `-r:`	If you use this parameter, script will request for your confirmation to apply operations after showing a summary in the console.
- `--upd-only`: If you us this parameter, script will only update repos and install dependencies (no tag will be created nor docker image will be built/pushed).
- `--push`: If you use this parameter:
	- A tag will be created, named as the version being used (var `$DOK_VERSION` in `update-and-push.env` or `-v` parameter), wich will point to `$REPO_BRANCH` last commit (see `update-and-push.env`).
	- Built Dockers will be pushed to ACR.

**IMPORTANT-1:** `<ver>` cannot start with `-`.
**IMPORTANT-2:** Parameters `--push` and `--upd-only` cannot be used in the same execution.
**IMPORTANT-3:** By default, no tag will be created nor docker will be built/pushed. To do that, you have to use `--push` parameter.
				
B. Modules (posible values for `<moduloi>`):

- `--iss-back`: *didi-issuer-back*.
- `--iss-front`: *didi-issuer-front*.
- `--jwt`: *didi-jwt-validator*.
- `--mouro`: *didi-mouro*.
- `--ronda`: *didi-ronda*.
- `--sem-be`: *semillas-middleware*.
- `--sem-fe`: *semillas-middleware-frontend*.
- `--server`: *didi-server*.

**IMPORTANT:** If modules are repeated between parameters, this script will only process them only one time.

### 2.1.3. Example

`./update-and-push.sh -v 0.5.0 -r --push --iss-front`

Running this command:

- Version `0.5.0` will be used for Dockers.
- Confirmation from user will be asked after the script shows operations summary.
- Built Docker images will be pushed to ACR.
- Tag `0.5.0` will be created and last commit from branch `$REPO_BRANCH` will be pushed.
- Only module *didi-issuer-back* will be processed.


