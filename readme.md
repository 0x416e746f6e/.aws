# Storing AWS CLI credentials in macOS keychain

>
> Scripts here assume that the following environment variables are correctly
> assigned in your `.zshrc`/`.bashrc`:
>
> - `AWS_ACCOUNT_ID`
> - `AWS_IAM_USERNAME`
>

Create AWS access key and run the script below.

```bash
# The spaces in front are to prevent storing secrets in terminal history
  AWS_ACCESS_KEY_ID=XXX
  AWS_SECRET_ACCESS_KEY=YYY

AWS_USER_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:user/$AWS_IAM_USERNAME"
AWS_CREDENTIALS="{\"Version\":1,\"AccessKeyId\":\"$AWS_ACCESS_KEY_ID\",\"SecretAccessKey\":\"$AWS_SECRET_ACCESS_KEY\"}"

security add-generic-password -l "$AWS_USER_ARN" -a "$AWS_USER_ARN" -s "$AWS_USER_ARN" -w "$AWS_CREDENTIALS"
```

## Using short-lived tokens with AWS CLI

1. Configure MFA with your AWS account.

2. Run `~/.aws/login.sh` and enter your one-time password from MFA. If
   all is Ok it will generate a short-lived auth token and store it in
   the keychain for later use by AWS CLI.
