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
   "log_in_directory" : "logs",                 #// Directory where logs are imported from (if api_download_logs == false)
   "log_out_directory" : "logs",                #// Directory where post-processed logs will go
   "api_download_logs": True,                   #// Process logs from...? True = Silo, false = logs directory
   "api_endpoint" : 'extapi.authentic8.com',    #// Should usually be 'extapi.authentic8.com'
   "api_org_name" : "",                         #// Organization name shown in the Silo Admin portal
   "api_token_file" : "token.txt",              #// File containing 32-char API key (login credential) provided by Silo.
   "log_type" : 'ENC',                          #// Log type to download or import. See Silo docs for other options (like 'LOG')
   "date_start": "",                            #// Blank = today, otherwise provide a valid date %Y-%m-%d e.g. '2020-01-30'
   "fetch_num_days" : 7,                        #// How many days back from date_start to download
   "seccure_passphrase_file": "seccure_key.txt",#// File containing seccure passphrase. Only required for seccure options.
   "seccure_decrypt_logs" : False,              #// Decrypt logs during processing?
   "seccure_show_pubkey": False,                #// Show the pubkey for the passphrase file?   
   "output_csv" : False,                        #// Post-process: Save results to .CSV files?
   "output_json" : True,                        #// Post-process: Save results to .JSON files?
   "output_console": True                       #// Post-process: Show logs on console window?
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

I have found gmpy2 in particular to be problematic as it tends to prefer building from source which can work poorly in some environments. 
The following will may be helpful in getting the binary gmpy2 installation and ignore SSL errors (e.g. by upstream firewalls), which may be helpful in locked-down environments.
```
python -m  pip install  --trusted-host pypi.python.org --trusted-host files.pythonhosted.org seccure
python -m  pip install --only-binary=:all: --trusted-host pypi.python.org --trusted-host files.pythonhosted.org gmpy2
```

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
