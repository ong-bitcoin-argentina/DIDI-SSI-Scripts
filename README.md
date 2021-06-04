
# DIDI-SSI-Scripts

# 1. Summary

This guide explains how to use different scripts in this repo.

# 2. Scripts

## 2.1. update-and-push

- Script for repo updating of *DIDI/Semillas*, and Docker image building/pushing. 
- A tag will be created, named as the version being used (variable `$DOK_VERSION` in `update-and-push.env` or `-v` parameter), wich will point to `$REPO_BRANCH` last commit (see `update-and-push.env`).
- Clone repo *DIDI-SSI-Scripts* in the same folder where the other *ong-bitcoin-argentina* repos are.
- Change *<CHANGE_ME>*  values in *update-and-push.env.example* and save changes in a new file named *update-and-push.env*.
- Don't change the folder where this script lives.
- Double check that the full path to this script in your local computer doesn't contain spaces nor reserved characters.
- Use your Linux console to go to local folder where this scripts lives and run it (not as *sudo*).

### 2.1.1. Dependencies

- *azure*: `apt-get install azure-cli`
- *curl*: `apt-get install curl`
- *git*: `apt-get install git`
- *docker*:  https://docs.docker.com/engine/install/ubuntu/
- *python*: `apt-get install python`
- *JDK11*: `apt install default-jdk`
- *maven*: `apt-get install maven`
- *nvm*: `curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash`

### 2.1.2. Parameters

A. Optional parameters:

`[ <module1> <module2> ... <moduloe> ] [ -r --push|--upd-only ]`
		
- `<modulei>`: Module to be processed with this script.
- `-r:`	If you use this parameter, script will request for your confirmation to apply operations after showing a summary in the console.
- `--push`: If you use this parameter, builded Dockers will be pushed to ACR (by default they are not).
- `--upd-only`: If you us this parameter, script will only update repos and install dependencies (no docker will be built/pushed).

**IMPORTANT:** Parameters `--push` and `--upd-only` cannot be used in the same execution.
				
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
- Tag `0.5.0` will be created and last commit from branch `$REPO_BRANCH` will be pushed.
- Confirmation from user will be asked after the script shows operations summary.
- Only module *didi-issuer-back* will be processed.


