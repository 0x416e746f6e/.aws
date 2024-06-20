AWS_MFA_DEVICE="arn:aws:iam::${AWS_ACCOUNT_ID}:mfa/${AWS_IAM_USERNAME}"
AWS_USER_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:user/${AWS_IAM_USERNAME}"

function get_1fa_token() {
  security find-generic-password \
    -l "$AWS_USER_ARN" \
    -a "$AWS_USER_ARN" \
    -s "$AWS_USER_ARN" \
    -w
}

function get_2fa_token() {
  security find-generic-password \
    -l "${AWS_MFA_DEVICE}" \
    -a "${AWS_MFA_DEVICE}" \
    -s "${AWS_MFA_DEVICE}" \
    -w
}

function save_2fa_token() {
  local AWS_SESSION_TOKEN=$1

  if [[ -n "${DEBUG}" ]]; then
    echo "New AWS_SESSION_TOKEN: ${AWS_SESSION_TOKEN}" >> ${HOME}/.aws/debug.log
  fi

  if [[ -z "${DEBUG}" ]]; then
    security delete-generic-password \
        -l "${AWS_MFA_DEVICE}" \
        -a "${AWS_MFA_DEVICE}" \
        -s "${AWS_MFA_DEVICE}" \
      > /dev/null 2>&1 || true

    security add-generic-password \
        -l "${AWS_MFA_DEVICE}" \
        -a "${AWS_MFA_DEVICE}" \
        -s "${AWS_MFA_DEVICE}" \
        -w "${AWS_SESSION_TOKEN}" \
      > /dev/null 2>&1 || true
  else
    security delete-generic-password \
        -l "${AWS_MFA_DEVICE}" \
        -a "${AWS_MFA_DEVICE}" \
        -s "${AWS_MFA_DEVICE}" \
      >> ${HOME}/.aws/debug.log 2>&1 || true

    security add-generic-password \
        -l "${AWS_MFA_DEVICE}" \
        -a "${AWS_MFA_DEVICE}" \
        -s "${AWS_MFA_DEVICE}" \
        -w "${AWS_SESSION_TOKEN}" \
      >> ${HOME}/.aws/debug.log
    fi
}

function request_2fa_token() {
  echo "Logging into AWS..." >&2

  if ykman=$( which ykman ); then
    if [ -z "$( ykman list )" ]; then
      echo "Please insert your yubikey and hit <ENTER>..." >&2
      read
    fi
    PIN=$( $ykman oath accounts code --single ${AWS_MFA_DEVICE} )
  else
    # TODO: Implement 1password integration
    printf "Enter one-time password for \`${AWS_MFA_DEVICE}\`: " >&2
    read PIN
  fi

  echo "Requesting session token from AWS API..." >&2

  if ! AWS_SESSION_TOKEN=$( aws \
        --profile 1fa \
      sts get-session-token \
        --serial-number ${AWS_MFA_DEVICE} \
        --duration-seconds 3600 \
        --token-code $PIN \
    | jq -r -c ".Credentials + { \"Version\": 1 }"
  ); then
    echo "Failed to retrieve AWS session token" >&2
    exit 1
  fi

  echo "Done." >&2

  printf "${AWS_SESSION_TOKEN}"
}
