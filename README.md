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

If any of the 'seccure_*' options are set to true (e.g. decryption), then the `seccure` python package is also required. It can be found on [Pypi](https://pypi.org/project/seccure/).
Please note for offline installations that seccure has a number of sub-dependencies that may need to be moved over:
 - [six](https://pypi.org/project/six/)
 - [pycryptodome](https://pypi.org/project/pycryptodome/)
 - [gmpy2](https://pypi.org/project/gmpy2/)

### Troubleshooting Dependencies

In cross-platform / offline scenarios, it may be necessary to compile one or more of the dependencies, which may bring in requirements for python3-devel, or to manually transfer the appropriate wheel files from pypi. It may also be necessary to rename some wheel files depending on your linux distribution.

I have found gmpy2 in particular to be problematic as it tends to prefer building from source which can work poorly in some environments. 

The following can be used to install the binary gmpy2 installation and ignore SSL errors (e.g. by upstream firewalls), which may be helpful in locked-down environments.
```
python -m  pip install --only-binary=:all: --trusted-host pypi.python.org --trusted-host files.pythonhosted.org gmpy2
python -m  pip install  --trusted-host pypi.python.org --trusted-host files.pythonhosted.org seccure
```

### Incompatible Platform

Some combinations of Linux distro and python version do not like the wheel files provided by PyPi.org (e.g. for pycryptodome) and complain of an incompatible platform.

To troubleshoot this, first determine what platform tags your version of python supports either from the command line: 

`python -m pip debug --verbose`

or from within the python interpreter

```python
import packaging.tags
tags = packaging.tags.sys_tags()
print('\n'.join([f'{tag.interpreter}-{tag.abi}-{tag.platform}' for tag in tags]))
```

Once you have that, you should be able to download the matching version from PyPi.org.

Note that some tags like `manylinux2014` and  `manylinux_2_17_x86_64` seem to be unsupported in some versions of pip. This can be worked around by renaming the problematic wheel file to a compatible tag before installing them:

```bash
cd /path/to/dependencies
mv gmpy2-2.1.5-cp36-cp36m-manylinux_2_17_x86_64.manylinux2014_x86_64.whl gmpy2-2.1.5-cp36-cp36m-linux_x86_64.whl
mv pycryptodome-3.20.0-cp35-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl pycryptodome-3.20.0-cp35-abi3-linux_x86_64.whl
python -m pip install --no-index --find-links /path/to/dependencies/ -r /path/to/requirements.txt
```



## Usage

### Standard Usage

 1. Set up `silo_config.json`
 2. Ensure any api keys or seccure passphrases have been added to `tokens.txt` or `seccure_key.txt` as appropriate
 3. `python3 .\silo_batch_pull.py`

### Docker Usage

The script can run in a Docker container with configuration and logs stored in persistent volumes.

#### Quick Start with Docker

1. **Build the Docker image:**
   ```bash
   docker build -t silo-log-pull .
   ```

2. **Create local directories for config and logs:**
   ```bash
   mkdir -p config logs
   ```

3. **Add your configuration files to the `config` directory:**
   - `config/base_config.json` - Main configuration file
   - `config/token.txt` - Your Silo API token
   - `config/seccure_key.txt` - Your seccure passphrase (if using decryption)

4. **Run the container:**
   ```bash
   docker run --rm \
     -v $(pwd)/config:/config \
     -v $(pwd)/logs:/logs \
     -e SILO_API_ORG_NAME="YourOrgName" \
     silo-log-pull
   ```

#### Using Docker Compose

1. **Create a `.env` file with your organization name:**
   ```bash
   echo "SILO_API_ORG_NAME=YourOrgName" > .env
   ```

2. **Start the service:**
   ```bash
   docker-compose up
   ```

#### Docker Environment Variables

When running in Docker mode (detected via `DOCKER_CONTAINER=true`), the script automatically uses:
- `/config` for configuration files (base_config.json, token.txt, seccure_key.txt)
- `/logs` for log input/output

All configuration settings can be overridden using environment variables:

| Environment Variable | Description | Default (Docker) |
|---------------------|-------------|------------------|
| `SILO_SETTINGS_PATH` | Path to config file | `/config/base_config.json` |
| `SILO_LOG_IN_DIR` | Log input directory | `/logs` |
| `SILO_LOG_OUT_DIR` | Log output directory | `/logs` |
| `SILO_API_DOWNLOAD` | Download from API (true/false) | `true` |
| `SILO_API_ENDPOINT` | API endpoint | `extapi.authentic8.com` |
| `SILO_API_ORG_NAME` | Organization name (required) | - |
| `SILO_API_TOKEN_FILE` | API token file path | `/config/token.txt` |
| `SILO_LOG_TYPE` | Log type (ENC, LOG, etc.) | `ENC` |
| `SILO_DATE_START` | Start date (YYYY-MM-DD) | Today |
| `SILO_FETCH_NUM_DAYS` | Days to fetch | `7` |
| `SILO_SECCURE_PASSPHRASE_FILE` | Seccure passphrase file | `/config/seccure_key.txt` |
| `SILO_SECCURE_DECRYPT` | Decrypt logs (true/false) | `false` |
| `SILO_SECCURE_SHOW_PUBKEY` | Show public key (true/false) | `false` |
| `SILO_OUTPUT_CSV` | Output CSV files (true/false) | `false` |
| `SILO_OUTPUT_JSON` | Output JSON files (true/false) | `true` |
| `SILO_OUTPUT_CONSOLE` | Display on console (true/false) | `true` |
| `SILO_WEB_INTERFACE` | Enable web interface (true/false) | `true` |
| `SILO_WEB_INTERFACE_PORT` | Web interface port | `8080` |

**Example with environment variables:**
```bash
docker run --rm \
  -v $(pwd)/config:/config \
  -v $(pwd)/logs:/logs \
  -e SILO_API_ORG_NAME="YourOrgName" \
  -e SILO_FETCH_NUM_DAYS=30 \
  -e SILO_DATE_START="2024-01-01" \
  -e SILO_SECCURE_DECRYPT=true \
  -e SILO_OUTPUT_CSV=true \
  silo-log-pull
```

## Roadmap
 - [x] Update filesystem code to use cross-OS native code (current code relies on Windows conventions)
 - [x] Support arbitrary date ranges
 - [x] Support alternate directories for import and download

## License
See the LICENSE.md file for details.

## Project status
Active as of 2024-02-06
