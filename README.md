
# DIDI-SSI-Scripts

# 1. Summary

This guide explains how to use different scripts in this repo.

# 2. Scripts

## 2.1. update-and-push

- Script for repo updating of *DIDI/Semillas*, and Docker image building/pushing. 
- Clone repo *DIDI-SSI-Scripts* in the same folder where the other *ong-bitcoin-argentina* repos are.
- Change *<CHANGE_ME>*  values in *update-and-push.env.example* and save changes in a new file named *update-and-push.env*.
- Don't change the folder where this script lives.
- Double check that the full path to this script in your local computer doesn't contain spaces nor reserved characters.
- Use your Linux console to go to local folder where this scripts lives and run it (not as *sudo*).

### 2.1.1. Dependencies

- *curl*: `apt-get install curl`
- *git*: `apt-get install git`
- *docker*:  https://docs.docker.com/engine/install/ubuntu/
- *python*: `apt-get install python`
- *JDK11*: `apt install default-jdk`
- *maven*: `apt-get install maven`
- *nvm*: `curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash`

### 2.1.2. Parameters

Optional parameters:
`[ <module1> <module2> ... <moduloe> ] [ --dont-push ]`
		
- `<modulei>`: Module to be processed with this script.
- `--dont-push`: If you use this parameter, builded Dockers won't be pushed to ACR.
				
Modules (posible values for `<moduloi>`):

- `--iss-back`: *didi-issuer-back*.
- `--iss-front`: *didi-issuer-front*.
- `--jwt`: *didi-jwt-validator*.
- `--mouro`: *didi-mouro*.
- `--ronda`: *didi-ronda*.
- `--sem-be`: *semillas-middleware*.
- `--sem-fe`: *semillas-middleware-frontend*.
- `--server`: *didi-server*.

**IMPORTANT:** If modules are repeated between parameters, this script will only process them only one time.


