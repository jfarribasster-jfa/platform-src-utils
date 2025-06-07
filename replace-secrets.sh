#!/bin/bash

# *************************************************
# *** Include source file for utility functions ***
# *************************************************
source ./source-utils.sh

# *************************************************
# *** Getting parameters ***
# *************************************************
KV_PATH=$1
FILENAME_TO_REPLACE=$2
ROLE_ID=$3
SECRET_ID=$4

# *********************************************
# *** Replace secrets in the specified file ***
# *********************************************
replace-secrets ${KV_PATH} ${FILENAME_TO_REPLACE} ${ROLE_ID} ${SECRET_ID}   
