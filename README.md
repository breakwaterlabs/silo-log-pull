# silo-log-pull

This script updates the example silo log script from https://support.authentic8.com/support/solutions/articles/16000027682.

The scripts there were written for python2 and are difficult to run today. In addition, they are not well suited to an automated process.

This script aims to fix that by providing configuration via a JSON file that can support a number of scenarios. In particular, this is designed to support traditional single-shot "download and decrypt", or more secure low-side download / high-side decrypt scenarios.

It also provides robust error handling and be resilient to misconfiguration.

## Getting started

Simply download the python script and run it. If you do not have a `silo_config.json`, the script will create one with default values. Note that you will be required to change at least one configuration for the script to launch, as by default it will have no customer org configured and no API key with which to download logs.

## Configuring the script

The current options in `silo_config.json` are as follows (along with their current default values):
```
{
   "ea_host" : 'extapi.authentic8.com',         # The authentic8 API endpoint. This should not change.
   "customer_org" : "",                         # Customer org as shown in the web console. Required if download_logs == true
   "token_file_path" : "token.txt",             # Path of file containing just API key. Required if download_logs == True
   "log_type" : 'ENC',                          # Valid types from silo docs. Only used if download_logs == true. Only tested with 'ENC'
   "fetch_num_days" : 7,                        # Number of days back from today to fetch / import / process
   "output_directory" : "logs",                 # Directory where logs are downloaded to, or imported from when download is off
   "output_csv" : True,                         # Output to CSV (decrypted, if decrypt_logs == true)
   "output_json" : False,                       # Output to JSON (decrypted, if decrypt_logs == true)
   "output_console": True,                      # Display logs on-screen as they are processed
   "download_logs": False,                      # True: fetch logs from authentic8; False: import from output_directory for processing
   "decrypt_logs" : True,                       # Decrypt after download / import before output?
   "decrypt_passphrase_file": "seccure_key.txt",# Location of file containing just the plain-text seccure passphrase (not public key)   
   "display_seccure_pubkey": False              # True: display seccure pubkey in console and pause for input.
}
```

## Installation
This script requires Python 3. It has been tested on 3.6 and 3.12.
It also requires the `seccure` package found on [Pypi](https://pypi.org/project/seccure/).
Please note for offline installations that seccure has a number of sub-dependencies that may need to be moved over:
 - [six](https://pypi.org/project/six/)
 - [pycryptodome](https://pypi.org/project/pycryptodome/)
 - [gmpy2](https://pypi.org/project/gmpy2/)

In cross-platform / airgap scenarios, it may be necessary to compile one or more of those, which may bring in requirements for  python3-devel, or to manually transfer the appropriate wheel files from pypi (and to potentially rename them).

## Usage

 1. Set up `silo_config.json`
 2. Ensure any api keys or seccure passphrases have been added to `tokens.txt` or `seccure_key.txt` as appropriate
 3. `python3 .\silo_batch_pull.py`

## Roadmap
 - [ ] Update filesystem code to use cross-OS native code (current code relies on Windows conventions)
 - [ ] Support arbitrary date ranges
 - [ ] Support alternate directories for import and download

## License
See the LICENSE.md file for details.

## Project status
Active as of 2024-02-06
