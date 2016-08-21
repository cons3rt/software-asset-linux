#!/bin/bash

# Sample Asset Installation Script

echo "CONS3RT is running this sample software asset ..."

################################
# SPECIAL ENVIRONMENT VARIABLES
################################

echo "CONS3RT_HOME = ${CONS3RT_HOME}"

echo "ASSET_DIR is a special environment variable pointing to the parent directory of this asset!"
echo "ASSET_DIR = ${ASSET_DIR}"

echo "List the contents of ASSET_DIR:"
find ${ASSET_DIR}

echo "DEPLOYMENT_HOME is a special environment variable point to the deployment.properties file!"
echo "DEPLOYMENT_HOME = ${DEPLOYMENT_HOME}"

echo "List the contents of deployment.properties:"
cat ${DEPLOYMENT_HOME}/deployment.properties

################################
# LOGGING IS YOUR FRIEND
################################

echo "Logging is your friend! Check for everything to do and log the result!"
echo "Check to make sure everything you're going to use exists"

# Check to make sure ASSET_DIR exists
if [ -z ${ASSET_DIR} ] ; then
	echo "ASSET_DIR doesn't exist!"
	exit 1
else
	echo "ASSET_DIR found and set to: ${ASSET_DIR}"
fi

echo "Logs are located here: /opt/cons3rt-agent/log"

################################
# EXIT CODES
################################

# Try changing this value and installing on CONS3RT to see how CONS3RT behaves
exitCode=0

echo "CONS3RT considers the asset a success if this script returns exit code: 0"
echo "Non-zero exit codes will tell CONS3RT to error out and notify you there was an error"

echo "Exiting with code ${exitCode}"
exit #{exitCode}

