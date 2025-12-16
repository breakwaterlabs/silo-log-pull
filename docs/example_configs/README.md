# Example configs

These directories contain example configurations, which generally consist of the following files:
 - `silo_config.json` : the main configuration file
 - `seccure_key.txt`: where the (optional) seccure passphrase is stored. This is only needed when decryption options are configured
 - `token.txt`: where the (optional) authentic8 API key is stored. This is only needed when downloading logs from the A8 endpoint

All paths / file names are configurable in `silo_config.json`, except for the config file itself.

Descriptions of each of the scenarios supported by these configs can be found in the respective README files under each directory.
