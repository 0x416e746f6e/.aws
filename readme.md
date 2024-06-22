# aws-cli-manager

Storing AWS CLI credentials in macOS keychain.

## Supported environments

OS:
- MacOS

Shells:
- zsh
- bash

OTP Engines:
- Yubikey
- 1password
- Manual

## Quick start

```bash
# Linux
curl -sL https://raw.githubusercontent.com/0x416e746f6e/.aws/main/awsup.sh | bash
```

## Manual start

>
> Scripts here assume that the following environment variables are correctly
> assigned in your shell profile. You can do this using the setup flag shown
> below or manually:
>
> Required:
> - `AWS_ACCOUNT_ID`
> - `AWS_IAM_USERNAME`
>
> Optional:
> - `AWS_OP_ITEM` - The item name or ID of your AWS OTP credential in 1password.
>

Create AWS access key and run the script below:

```bash
# The spaces in front are to prevent storing secrets in terminal history
  AWS_ACCESS_KEY_ID=XXX
  AWS_SECRET_ACCESS_KEY=YYY

AWS_USER_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:user/${AWS_IAM_USERNAME}"
AWS_CREDENTIALS="{\"Version\":1,\"AccessKeyId\":\"$AWS_ACCESS_KEY_ID\",\"SecretAccessKey\":\"$AWS_SECRET_ACCESS_KEY\"}"

security add-generic-password -l "$AWS_USER_ARN" -a "$AWS_USER_ARN" -s "$AWS_USER_ARN" -w "$AWS_CREDENTIALS"
```

## Using short-lived tokens with AWS CLI

1. Configure MFA with your AWS account.

2. Run `~/.aws/manager.sh` and enter your one-time password from MFA. If
   all is Ok it will generate a short-lived auth token and store it in
   the keychain for later use by AWS CLI.

## Using an existing aws config

After setup, you can specify a custom config file. This lets private
data like roles and account IDs to be managed privately.

> Note that `mfa_device` must be absent from your config file.

```bash
# File
~/.aws/manager.sh --custom-config /path/to/config

# URL
~/.aws/manager.sh --custom-config https://config
```
