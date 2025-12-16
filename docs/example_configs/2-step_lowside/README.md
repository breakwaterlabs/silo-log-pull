# Example: 2-step process, low side

This config set supports the high-side of a "seperation of duties" process, where files are downloaded in an encrypted format, and transferred to a secure system where they are decrypted.

This low-side config will download files in an encrypted format using the api key in token.txt. They can then safely be moved in their (still-encrypted) form to a secure system where they can be processed and decrypted.

Because no connection to authentic8 is made, no api key is needed-- truly supporting the seperation of duties. Only the low side has access to the API key to perform the download, and only the high side has access to the keys to decrypt the logs.
