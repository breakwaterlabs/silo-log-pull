# Example: 1-step process / download and decrypt

This config set supports general use case where logs are downloaded, decrypted, and processed all in one system.

The script will read in the api key from token.txt, validate / display the public key from seccure_key.txt, download the logs in an encrypted form, and decrypt them to the desired (JSON / CSV) formats.

This is less secure than the two-step process but still maintains the end-to-end security of Silo's log encryption.
