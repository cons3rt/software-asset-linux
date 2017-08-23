#!/bin/bash

# Source the environment
if [ -f /etc/bashrc ] ; then
    . /etc/bashrc
fi
if [ -f /etc/environment ] ; then
    . /etc/environment
fi

# Establish a log file and log tag
logTag="sample-linux-asset"
logDir="/var/log/cons3rt"
logFile="${logDir}/${logTag}-$(date "+%Y%m%d-%H%M%S").log"

######################### GLOBAL VARIABLES #########################

# Array to maintain exit codes of RPM install commands
resultSet=();

# The linux distro
distroId=
distroVersion=
distroFamily=

# Package list
packageManager=
packageList="vim emacs"

# Asset media directory
mediaDir=

####################### END GLOBAL VARIABLES #######################

# Logging functions
function timestamp() { date "+%F %T"; }
function logInfo() { echo -e "$(timestamp) ${logTag} [INFO]: ${1}" >> ${logFile}; }
function logWarn() { echo -e "$(timestamp) ${logTag} [WARN]: ${1}" >> ${logFile}; }
function logErr() { echo -e "$(timestamp) ${logTag} [ERROR]: ${1}" >> ${logFile}; }

function set_asset_dir() {
    # Ensure ASSET_DIR exists, if not assume this script exists in ASSET_DIR/scripts
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    if [ -z "${ASSET_DIR}" ] ; then
        logWarn "ASSET_DIR not found, assuming ASSET_DIR is 1 level above this script ..."
        export ASSET_DIR="${SCRIPT_DIR}/.."
    fi
    mediaDir="${ASSET_DIR}/media"
}

function run_and_check_status() {
    "$@" >> ${logFile} 2>&1
    local status=$?
    if [ ${status} -ne 0 ] ; then
        logErr "Error executing: $@, exited with code: ${status}"
    else
        logInfo "$@ executed successfully and exited with code: ${status}"
    fi
    resultSet+=("${status}")
    return ${status}
}

function set_deployment_home() {
    # Ensure DEPLOYMENT_HOME exists
    if [ -z "${DEPLOYMENT_HOME}" ] ; then
        logWarn "DEPLOYMENT_HOME is not set, attempting to determine..."
        deploymentDirCount=$(ls /opt/cons3rt-agent/run | grep Deployment | wc -l)
        # Ensure only 1 deployment directory was found
        if [ ${deploymentDirCount} -ne 1 ] ; then
            logErr "Could not determine DEPLOYMENT_HOME"
            return 1
        fi
        # Get the full path to deployment home
        deploymentDir=$(ls /opt/cons3rt-agent/run | grep "Deployment")
        deploymentHome="/opt/cons3rt-agent/run/${deploymentDir}"
        export DEPLOYMENT_HOME="${deploymentHome}"
    else
        deploymentHome="${DEPLOYMENT_HOME}"
    fi
}

function read_deployment_properties() {
    local deploymentPropertiesFile="${DEPLOYMENT_HOME}/deployment-properties.sh"
    if [ ! -f ${deploymentPropertiesFile} ] ; then
        logErr "Deployment properties file not found: ${deploymentPropertiesFile}"
        return 1
    fi
    . ${deploymentPropertiesFile}
    return $?
}

function get_distro() {
    if [ -f /etc/os-release ] ; then
        . /etc/os-release
        if [ -z "${ID}" ] ; then logErr "Linux distro ID not found"; return 1;
        else distroId="${ID}"; fi;
        if [ -z "${VERSION_ID}" ] ; then logErr "Linux distro version ID not found"; return 2
        else distroVersion="${VERSION_ID}"; fi;
        if [ -z "${ID_LIKE}" ] ; then logErr "Linux distro family not found"; return 3
        else distroFamily="${ID_LIKE}"; fi;
    elif [ -f /etc/centos-release ] ; then
        distroId="centos"
        distroVersion=$(cat /etc/centos-release | sed "s|Linux||" | awk '{print $3}' | awk -F . '{print $1}')
        distroFamily="rhel fedora"
    elif [ -f /etc/redhat-release ] ; then
        distroId="rhel"
        distroVersion=$(cat /etc/redhat-release | awk '{print $7}' | awk -F . '{print $1}')
        distroFamily="rhel fedora"
    else logErr "Unable to determine the Linux distro or version"; return 4; fi;
    logInfo "Detected Linux Distro ID: ${distroId}"
    logInfo "Detected Linux Version ID: ${distroVersion}"
    logInfo "Detected Linux Family: ${distroFamily}"
    return 0
}

function get_package_manager() {
    if [ -e /usr/bin/yum ] ; then
        packageManager="yum"
    else
        packageManager="apt-get"
    fi
    logInfo "Using package manager: ${packageManager}"
}

function update_packages() {
    logInfo "Updating packages..."
    ${packageManager} -y update >> ${logFile} 2>&1
    resultSet+=("${?}")
    if [[ "${packageManager}" == "apt-get" ]] ; then
        ${packageManager} -y upgrade >> ${logFile} 2>&1
        resultSet+=("${?}")
    fi
}

function install_packages() {
    logInfo "Installing packages: ${packageList}"
    ${packageManager} -y install ${packageList} >> ${logFile} 2>&1
    result=$?
    resultSet+=("${result}")
    return ${result}
}

function create_config_file() {
# This is an example for how to create a dynamic config file
logInfo "Creating the credentials file..."
cat << EOF >> /root/.aws/credentials
[default]
aws_access_key_id = ${AWS_ACCESS_KEY}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
EOF
}

function main() {
    set_asset_dir
    set_deployment_home
    read_deployment_properties
    get_package_manager
    update_packages
    install_packages
    create_config_file

    # Check the results of commands from this script, return error if an error is found
    for res in "${resultSet[@]}" ; do
        if [ ${res} -ne 0 ] ; then logErr "Non-zero exit code found: ${res}"; return 1; fi
    done

    # Exit successfully
    logInfo "Successfully completed: ${logTag}"
    return 0
}

# Set up the log file
mkdir -p ${logDir}
chmod 700 ${logDir}
touch ${logFile}
chmod 644 ${logFile}

main
result=$?
cat ${logFile}

logInfo "Exiting with code ${result} ..."
exit ${result}
