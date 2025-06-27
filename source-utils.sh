#!/bin/bash


vault_kv_login() {
  
    echo "$(date +%Y%m%d) $(date +%H:%M:%S) - INFO - Logging in to Vault using AppRole"
  
    local ROLE_ID=$1
    local SECRET_ID=$2
    local VAULT_DNS="ec2-35-153-200-234.compute-1.amazonaws.com:8200"  
    local DAT="{\"role_id\":\"${ROLE_ID}\",\"secret_id\":\"${SECRET_ID}\"}"
    local ACCESS_TOKEN=$(curl -s -X POST --data $DAT http://$VAULT_DNS/v1/auth/approle/login | jq '.auth.client_token' | sed 's/"//g')
    export VAULT_ADDR=http://$VAULT_DNS
    export VAULT_TOKEN=$ACCESS_TOKEN 
    export HCP_CONFIG_DISABLE=true
    export HOME=/tmp
}


# ********************************************************************************
# ***  Replace Secrets from an Key Vault in a filename ***
# ***  Example: replace-secrets pthon/rsvpapp/main rsvp.yaml xxxx xxxx   ***
# ********************************************************************************
replace-secrets () {

  # **********************************
  # ***  Getting input parameters  ***
  # **********************************
  local ENVIRONMENT=$1
  local FILENAME_TO_REPLACE=$2
  local ROLE_ID=$3
  local SECRET_ID=$4

  # Login KV
  vault_kv_login $ROLE_ID $SECRET_ID

  # ********************************************************
  # ***  Replacing Secrets in file from Hashicolrp Key Vault  ***
  # ********************************************************
  echo "$(date +%Y%m%d) $(date +%H:%M:%S) - INFO - Replacing secrets for environment ${ENVIRONMENT} KV in file: ${FILENAME_TO_REPLACE}"

  while [ $(sed -n 's/.*\(#{[-[:alnum:]]*}#\).*/\1/p' $FILENAME_TO_REPLACE | sort -u | sed 's/#{//g' | sed 's/}#//g' | wc -l) -gt 0 ]; do
     local SECRETS_FOUND=$(sed -n 's/.*\(#{[-[:alnum:]]*}#\).*/\1/p' $FILENAME_TO_REPLACE | sort -u | sed 's/#{//g' | sed 's/}#//g' | wc -l)
     echo "$(date +%Y%m%d) $(date +%H:%M:%S) - INFO - Secrets founds: $SECRETS_FOUND"
     local SECRETS=`sed -n 's/.*\(#{[-[:alnum:]]*}#\).*/\1/p' $FILENAME_TO_REPLACE | sort -u | sed 's/#{//g' | sed 's/}#//g'`
     for SECRET in ${SECRETS[@]};
     do
       vault kv get -mount=secret -field=${SECRET} ${ENVIRONMENT}/${SECRET} > /dev/null
       local RESULT=$?
        if [ $RESULT -eq 0 ]; then
           echo "$(date +%Y%m%d) $(date +%H:%M:%S) - INFO - Replacing the Secret ${SECRET} in filename ${FILENAME_TO_REPLACE}"
           local VALUE=$(vault kv get -mount=secret -field=${SECRET} ${ENVIRONMENT}/${SECRET}  | sed 's/"//g')
           # Escaping the slashes and '&' characters in the value
           VALUE=$(echo "$VALUE" | sed -r "s/\//\\\\\//g;s/\&/\\\\\&/g")
           local SED_COMMAND="sed -i 's/#{$SECRET}#/$VALUE/g' $FILENAME_TO_REPLACE"
           #echo "$(date +%Y%m%d) $(date +%H:%M:%S) - INFO - Secret ${VALUE}"
           eval "$SED_COMMAND"
       else
           echo "$(date +%Y%m%d) $(date +%H:%M:%S) - ERROR - The following Secret has not been found: $SECRET"
           exit 1
        fi
     done

  done
}