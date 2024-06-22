AWS_MFA_DEVICE="arn:aws:iam::${AWS_ACCOUNT_ID}:mfa/${AWS_IAM_USERNAME}"
AWS_USER_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:user/${AWS_IAM_USERNAME}"

function get_1fa_token() {
  security find-generic-password \
    -l "${AWS_USER_ARN}" \
    -a "${AWS_USER_ARN}" \
    -s "${AWS_USER_ARN}" \
    -w
}

function get_2fa_token() {
  security find-generic-password \
    -l "${AWS_MFA_DEVICE}" \
    -a "${AWS_MFA_DEVICE}" \
    -s "${AWS_MFA_DEVICE}" \
    -w
}

function save_1fa_token() {
  local AWS_USER_ARN="$1"
  local AWS_CREDENTIALS="$2"

  if [[ -n "${DEBUG}" ]]; then
    echo "New AWS_CREDENTIALS" >> "${HOME}/.aws/debug.log"
  fi

  security delete-generic-password \
      -l "${AWS_USER_ARN}" \
      -a "${AWS_USER_ARN}" \
      -s "${AWS_USER_ARN}" \
    > /dev/null 2>&1 || true

  security add-generic-password \
      -l "${AWS_USER_ARN}" \
      -a "${AWS_USER_ARN}" \
      -s "${AWS_USER_ARN}" \
      -w "${AWS_CREDENTIALS}" \
    > /dev/null 2>&1 || true
}

function save_2fa_token() {
  local AWS_SESSION_TOKEN="$1"

  if [[ -n "${DEBUG}" ]]; then
    echo "New AWS_SESSION_TOKEN: ${AWS_SESSION_TOKEN}" >> "${HOME}/.aws/debug.log"
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
      >> "${HOME}/.aws/debug.log" 2>&1 || true

    security add-generic-password \
        -l "${AWS_MFA_DEVICE}" \
        -a "${AWS_MFA_DEVICE}" \
        -s "${AWS_MFA_DEVICE}" \
        -w "${AWS_SESSION_TOKEN}" \
      >> "${HOME}/.aws/debug.log"
    fi
}

function request_2fa_token() {
  echo "ℹ️ Logging into AWS..." >&2

  if ykman=$( which ykman ); then
    if [ -z "$( ykman list )" ]; then
      echo "Please insert your yubikey and hit <ENTER>..." >&2
      read
    fi
    PIN=$( $ykman oath accounts code --single ${AWS_MFA_DEVICE} )
  elif op=$(which op); then
    PIN=$(op item get ${AWS_OP_ITEM} --otp 2>/dev/null || echo "")
    if [ -z "${PIN}" ]; then
      echo "Enter the name or ID of your 1password item:" >&2
      set_profile_env "AWS_OP_ITEM" "${PROMPT_AWS_OP_ITEM}"
      read PIN
    fi
  else
    printf "Enter one-time password for \`${AWS_MFA_DEVICE}\`: " >&2
    read PIN
  fi

  echo "ℹ️ Requesting session token from AWS API..." >&2

  if ! AWS_SESSION_TOKEN=$( aws \
        --profile 1fa \
      sts get-session-token \
        --serial-number ${AWS_MFA_DEVICE} \
        --duration-seconds 3600 \
        --token-code ${PIN} \
    | jq -r -c ".Credentials + { \"Version\": 1 }"
  ); then
    echo "🚫 Failed to retrieve AWS session token" >&2
    exit 1
  fi

  echo "✅ Done." >&2

  printf "${AWS_SESSION_TOKEN}"
}

function save_custom_config() {
  local AWS_CONFIG_SOURCE="$1"
  local AWS_CONFIG_DEST="${HOME}/.aws/config"

  if [[ -f "${AWS_CONFIG_SOURCE}" ]]; then
    cp "${AWS_CONFIG_SOURCE}" "${AWS_CONFIG_DEST}"
  elif [[ "${AWS_CONFIG_SOURCE}" =~ ^http ]]; then
    if command -v curl >/dev/null 2>&1; then
      curl -sL -o "${AWS_CONFIG_DEST}" "${AWS_CONFIG_SOURCE}"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "${AWS_CONFIG_DEST}" "${AWS_CONFIG_SOURCE}"
    else
        echo "🚫 Neither curl nor wget are available. Please install one of these and try again."
        exit 1
    fi
  else
    echo "🚫 Invalid config source: ${AWS_CONFIG_SOURCE}" >&2
    exit 1
  fi
  echo "ℹ️ Saved config from: ${AWS_CONFIG_SOURCE} to ${AWS_CONFIG_DEST}" >&2
}

function get_profile() {
  case "${SHELL}" in
  */zsh)
      PROFILE="${ZDOTDIR-"$HOME"}/.zshrc"
      PREF_SHELL=zsh
      ;;
  */bash)
      PROFILE="${HOME}/.bashrc"
      PREF_SHELL=bash
      ;;
  *)
      echo "🚫 Shell not found."
      exit 1
  esac
  return "${PREF_SHELL}"
}

function get_prompt_string() {
    read -p "$1" CHOICE
    return "${CHOICE}"
}

function get_prompt_private_string() {
    stty -echo
    read -p "$1" CHOICE
    stty echo
    return "${CHOICE}"
}

function get_prompt_bool() {
    read -p "$1 [y/N]: " CHOICE
    case "${CHOICE}" in
      y|Y ) return 0;;
      * ) return 1;;
    esac
}

function set_profile_env() {
  local PROFILE="$( get_profile )"
  local KEY="$1"
  local VALUE="$2"

  if grep -q "^${KEY}=" "${PROFILE}"; then
    sed -i "s/^${KEY}=.*/${KEY}=${VALUE}/" "${PROFILE}"
    echo "🔄 The key '${KEY}' has been updated with value '${VALUE}' in the profile ${PROFILE}."
  else
    echo "${KEY}=${VALUE}" >> "$PROFILE"
    echo "✅ The key '${KEY}' with value '${VALUE}' has been added to the profile ${PROFILE}."
  fi
}

function save_setup() {
  local PROMPT_AWS_ACCOUNT_ID = "$( get_prompt_string )" "Enter your AWS account ID: "
  set_profile_env "AWS_ACCOUNT_ID" "${PROMPT_AWS_ACCOUNT_ID}"

  local PROMPT_AWS_IAM_USERNAME = "$( get_prompt_string )" "Enter your IAM username: "
  set_profile_env "AWS_IAM_USERNAME" "${PROMPT_AWS_IAM_USERNAME}"

  local PROMPT_AWS_2FA_ENGINE = "$( get_prompt_string )" "Do you use 1password or yubikey for 2fa? [1password/yubikey]: "
  if [[ "${PROMPT_AWS_2FA_ENGINE}" == "1password" ]]; then
      local PROMPT_AWS_OP_ITEM = "$( get_prompt_string )"  "Enter the name or ID of your 1password item: " >&2
      set_profile_env "AWS_OP_ITEM" "${PROMPT_AWS_OP_ITEM}"
  elif [[ "${PROMPT_AWS_2FA_ENGINE}" != "yubikey" ]]; then
      echo "🚫 Invalid 2fa method: ${PROMPT_AWS_2FA_ENGINE}" >&2
      exit 1
  fi

  if prompt_user_bool "Do you want to add a custom aws config file?" ; then
      local PROMPT_CUSTOM_CONFIG = "$( get_prompt_string )" "Enter the path or URL to the custom config file: "
      save_custom_config "${PROMPT_CUSTOM_CONFIG}"
  fi

  local PROMPT_AWS_ACCESS_KEY_ID="$( get_prompt_private_string )" "Enter your AWS access key ID: "
  local PROMPT_AWS_SECRET_ACCESS_KEY="$( get_prompt_private_string )" "Enter your AWS secret access key: "

  local AWS_USER_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:user/${AWS_IAM_USERNAME}"
  local AWS_CREDENTIALS="{\"Version\":1,\"AccessKeyId\":\"${AWS_ACCESS_KEY_ID}\",\"SecretAccessKey\":\"${AWS_SECRET_ACCESS_KEY}\"}"

  save_1fa_token "${AWS_USER_ARN}" "${AWS_CREDENTIALS}"

  echo "✅ Setup complete."
}

function set_lock() {
  if [[ -f "${HOME}/.aws/login.lock" ]]; then
    if [[ -t 0 ]]; then
      >&2 echo "🚫 Warning: another login attempt might be ongoing in parallel!"
    else
      exit 1
    fi
  fi

  touch "${HOME}/.aws/login.lock"
}

function delete_lock() {
  rm -f "${HOME}/.aws/login.lock"
}
