# Example: 2-step process, high side

This config set supports the high-side of a "seperation of duties" process, where files are downloaded in an encrypted format, and transferred to a secure system where they are decrypted.

The script will read in the files in the log directory as if they were downloaded, and will perform decryption using the key in seccure_key.txt.

Because no connection to authentic8 is made, no api key is needed-- truly supporting the seperation of duties. Only the low side has access to the API key to perform the download, and only the high side has access to the keys to decrypt the logs.
