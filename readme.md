## Storing AWS CLI credentials in macOS keychain

1. Create AWS access key, download the CSV and open it.

   There you will find <kbd>Access key ID</kbd> and
   <kbd>Secret access key</kbd>. Make note of them:

   ```bash
    _ACCESS_KEY_ID=XXX
    _SECRET_ACCESS_KEY=YYY
   ```

   **NOTE:** Add an extra space in the beginning of the command to
             prevent it being remembered by the `history` command.

2. Craft the JSON object that you will use to authenticate:

   ```bash
   _CREDENTIALS="{\"Version\":1,\"AccessKeyId\":\"$_ACCESS_KEY_ID\",\"SecretAccessKey\":\"$_SECRET_ACCESS_KEY\"}"
   ```

3. And now push them into the keychain:

   ```bash
   _USER="arn:aws:iam::176395444877:user/$( id -un )"

   security add-generic-password -l "$_USER" -a "$_USER" -s "$_USER" -w "$_CREDENTIALS"
   ```

## Using short-lived tokens with AWS CLI

1. Configure MFA with your AWS account.

2. Run `~/.aws/login.sh` and enter your one-time password from MFA. If
   all is Ok it will generate a short-lived auth token and store it in
   the keychain for later use by AWS CLI.
