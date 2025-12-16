#!/usr/bin/env python

#from getopt import getopt # Old school to support Python < 2.7
import json
import os
import sys
from datetime import date
from datetime import datetime
from datetime import timedelta
from pathlib import Path
import re

# Detect if running in Docker container
IS_DOCKER = os.environ.get('DOCKER_CONTAINER', '').lower() in ('true', '1', 'yes')

def get_env_value(env_var, default_value, value_type=str):
    env_value = os.environ.get(env_var)
    if env_value is None:
        return default_value
    if value_type == bool:
        return env_value.lower() in ('true', '1', 'yes')
    elif value_type == int:
        try:
            return int(env_value)
        except ValueError:
            return default_value
    else:
        return env_value

default_settings = {
   "data_dir"       : "data",           # Base directory containing config files and logs. Used to resolve relative paths.
   "settings_file"    : "silo_config.json", # Path to config file (relative to data_dir if not absolute).
   "non_interactive"  : False,            # Don't use interactive prompts
   "log_in_directory" : "logs",             # Directory where logs are imported from (relative to data_dir if not absolute).
   "log_out_directory" : "logs",            # Directory where post-processed logs will go (relative to data_dir if not absolute).
   "api_download_logs": True,               # Process logs from...? True = Silo, false = logs directory.
   "api_endpoint" : "extapi.authentic8.com", # Should usually be 'extapi.authentic8.com'.
   "api_org_name" : "",                     # Organization name shown in the Silo Admin portal.
   "api_token_file" : "token.txt",          # File containing 32-char API key (relative to data_dir if not absolute).
   "log_type" : "ENC",                      # Log type to download or import. See Silo docs for other options (like 'LOG').
   "date_start": "",                        # Blank = today, otherwise provide a valid date %Y-%m-%d e.g. '2020-01-30'.
   "fetch_num_days" : 7,                    # How many days back from start date to download.
   "seccure_passphrase_file": "seccure_key.txt", # File containing seccure passphrase (relative to data_dir if not absolute).
   "seccure_decrypt_logs" : False,          # Decrypt logs during processing?
   "seccure_show_pubkey": False,            # Show the pubkey for the passphrase file?
   "output_csv" : False,                    # Post-process: Save results to .CSV files?
   "output_json" : True,                    # Post-process: Save results to .JSON files?
   "output_console": True,                  # Post-process: Show logs on console window?
   "web_interface": True,                   # Activate web interface.
   "web_interface_port": 8080               # Listen port for web interface.
}
# Apply environment variable overrides (ENV: SILO_<KEY_NAME>)

for key in default_settings.keys():
   env_var_name = 'SILO_' + key.upper()
   value_type = type(default_settings[key])
   default_settings[key] = get_env_value(env_var_name, default_settings[key], value_type)
config=default_settings

if IS_DOCKER:
    print("Running in Docker mode - data files (config and logs) from /data")
    print("Environment variables will override default settings")
    print("######     Config file will override both.    ######")

def usage_abort( extra='', settings=True ):
   print("####################################################################")
   print("########################### FATAL ERROR ############################")
   print("####################################################################")
   if settings:
      print("\nMissing, incorrect, or invalid settings or files. The following settings are required in " + default_settings['settings_file'])
      print('   "api_org_name" : "<org>"')
      print("\nIf seccure_decrypt_logs or seccure_show_pubkey is True, then the following setting must be set to a file containing the seccure passphrase: ")
      print('   "seccure_passphrase_file" : "<seccure_key.txt>" ')
      print('\nOtherwise you can specify an alternate settings path by setting "settings_file" in' + default_settings['settings_file'])
   else:
      print("\nSomething went wrong unrelated to reading your settings.")
      print("\nThis is probably an issue with either the Authentic8 API endpoint, or your API key / Org name.")
   print("\nPlease see below for any specific error details:\n\n")
   print(extra)
   if not config["non_interactive"]:
      input("\nPress enter to exit...")
   sys.exit()

def create_settings_file(path, settings):
   try:
      if os.path.exists(path):
         os.rename(path, os.path.join(path, ".bak"))
      with open(path, "w") as jsonfile:
         jsonfile.write( json.dumps(settings, indent=4))
         jsonfile.close()
      print("Wrote settings file at " + path)
   except:
      usage_abort("Could not create a backup of your settings at:\n  " + path._str + ".bak\n" + "\nEither fix your current settings file or delete the existing backup.", settings=False )

def path_accessible(path, as_dir=False):
   if as_dir:
      return os.path.isdir(path) and os.access(path, os.R_OK)
   else:
      return os.path.isfile(path) and os.access(path, os.R_OK)

def resolve_paths(data_dir, filename):
   if not os.path.isabs(filename):
      filename = os.path.join(data_dir, filename)
   return Path(filename)

def import_json_config(resolved_settings_filepath, defaults):
   if path_accessible(resolved_settings_filepath):
      print("Settings file found. Importing settings.")
      with open(resolved_settings_filepath, "r") as jsonfile:
         try:
            file_config = json.load(jsonfile)
            # Check if data_dir and settings_file in file result in a different config location
            if not (file_config.get('data_dir') is None) and not (file_config.get('settings_file') is None):
               alternate_settings_filepath = resolve_paths(file_config['data_dir'], file_config['settings_file'])
               if alternate_settings_filepath != resolved_settings_filepath:
                  print(f"Found alternate settings path, using that instead: {alternate_settings_filepath}")
                  resolved_settings_filepath = alternate_settings_filepath
                  with open(alternate_settings_filepath, "r") as altfile:
                     file_config = json.load( file_config['settings_file'] )
            print("\nSuccessfully read config file at " + resolved_settings_filepath._str)
         except:
            usage_abort("Could not parse settings file '" + resolved_settings_filepath._str + "' as valid JSON. Either fix the file, rename it, or delete it and this script will create a new one.")
         jsonfile.close()
   else:
      create_settings_file(resolved_settings_filepath._str, defaults)
      print("Settings file was not found, so created new at " + resolved_settings_filepath._str)
      return defaults
   bad_settings = False
   for key in defaults.keys():
      usedefault=False
      if file_config.get(key) is None:
         reason = "setting was undefined in config"
         usedefault=True
      elif type(defaults[key]) != type(file_config[key]):
         reason = "setting had wrong type in config, " + str(type(defaults[key])) + " vs " + str(type(file_config[key]))
         usedefault=True
      if usedefault:
         bad_settings = True
         message = "(Used default, " + reason + ")" 
         file_config[key] = defaults[key]
      else:
         message = "(from config)"
      print( "Conf: {k:25s} = {s:25s} {m}".format(k = key, s = str(file_config[key]), m = message) )
   if bad_settings and not config["non_interactive"]:
      print("\n\n!! Some bad settings detected, so defaults were used. Please check that these are correct.")
      input("\nPress enter to continue, and create a fixed config file. A backup of your config file will be made.")
      print("Creating fixed config file. A backup of your config file will be made.")
      create_settings_file(resolved_settings_filepath, file_config)
   if file_config.get("api_org_name") is None:
      usage_abort( 'api_org_name must be defined.' )
   elif file_config["api_org_name"] == "":
      usage_abort( 'api_org_name must not be blank.' ) 
   return file_config

default_settings_file = resolve_paths(default_settings['data_dir'], default_settings['settings_file'])
config = import_json_config( default_settings_file, default_settings)
config["api_token_file"] = resolve_paths(config["data_dir"], config["api_token_file"])
config["seccure_passphrase_file"] = resolve_paths(config["data_dir"], config["seccure_passphrase_file"])
config["log_in_directory"] = resolve_paths(config["data_dir"], config["log_in_directory"])
config["log_out_directory"] = resolve_paths(config["data_dir"], config["log_out_directory"])

if config["seccure_decrypt_logs"] or config["seccure_show_pubkey"]:
   import seccure
   import base64
   if not config["seccure_passphrase_file"] or not path_accessible(config["seccure_passphrase_file"]):
      usage_abort("could not access the seccure_passphrase_file: " + config["seccure_passphrase_file"])
   pass_file = open( config["seccure_passphrase_file"], "rb" )
   passphrase = pass_file.read().rstrip()
   pass_file.close()
   seccure_curve = 'secp256r1/nistp256'
   if len(passphrase) < 1:
      usage_abort("Your passphrase file is empty. Please make sure you have specified a passphrase.")
   if len(passphrase) < 10:
      print("\nWarning: Your passphrase is very short. Please make a new passphrase that meets NIST recommendations to avoid this message.")
      if not config["non_interactive"]:
         input("Press enter to acknowledge.")
   if config["seccure_show_pubkey"]:
      pubkey = str(seccure.passphrase_to_pubkey(passphrase, curve=seccure_curve))
      print("\n\nConfig set to display pubkey.\n\n-----  Start Seccure Pubkey  -----\n" + pubkey + "\n------  End Seccure Pubkey  ------\n")
      if not config["non_interactive"]:
         input("Press enter to continue...")
      print("\n\n")

#in_dir = Path(re.sub(r'[^\w_. /\\-]', '_', config["log_in_directory"]))
#out_dir = Path(re.sub(r'[^\w_. /\\-]', '_', config["log_out_directory"]))
in_dir = config["log_in_directory"]
out_dir = config["log_out_directory"]

for dir in [out_dir, in_dir]:
   os.makedirs(dir, exist_ok=True)
   if not path_accessible(dir, True):
      usage_abort("Missing output directory / failed to create: " + dir)

if config["api_download_logs"]:
   import urllib.request, urllib.error, urllib.parse
   import base64
   cmd = {
      'command': 'extractlog',
      'org': config["api_org_name"],
      'type': config["log_type"]
   }
   if not (config.get("limit") is None):
      cmd['limit'] = config["limit"]
   if not path_accessible(config["api_token_file"]):
      usage_abort("api_token_file is not accessible")
   with open( config["api_token_file"], 'r' ) as token_file:
      apitoken = token_file.read().strip().replace(" ","")
   if not (base64.b64encode(base64.b64decode(apitoken)).decode('ascii') == apitoken and len(apitoken) == 32):
      usage_abort( "Check your API token. It should be 32 characters long in base64.\n"+ config["api_token_file"] + " : " + apitoken)
   else:
      print("\nUsing API token: " + apitoken)
   auth_cmd = {
      'command': 'setauth',
      'data': apitoken}
   token_file.close()
   url = 'https://' + config["api_endpoint"] + '/api/'
   headers = { 'Content-Type': 'application/json' }

if config['date_start'] == "":
   start_date = date.today()
else:
   try:
      start_date = datetime.strptime(config['date_start'],'%Y-%m-%d').date()
   except:
      usage_abort("Problem converting 'date_start' to datetime. Check that it is formatted as %Y-%m-%d : " + config['date_start'])

for i in range(config["fetch_num_days"]):
   this_day = (start_date - timedelta(days=i)).strftime('%Y-%m-%d')
   this_day_start = this_day + " 00:00:00"
   this_day_end = this_day + " 23:59:59"
   print("Date range: " + this_day_start + " - " + this_day_end)
   
   file_prefix_encrypted = 'silo_encrypted_' + this_day
   file_prefix_decrypted = 'silo_decrypted_' + this_day
   if config["api_download_logs"]:
      cmd['start_time'] = this_day_start
      cmd['end_time'] = this_day_end
      payload = json.dumps( [ auth_cmd, cmd ] ).encode('utf-8')
      request = urllib.request.Request( url, payload, headers ) 
      reader = urllib.request.urlopen( request )
      response = json.loads( reader.read() )
      reader.close()
      assert len( response ) == 2
      if not 'result' in response[1]:
         errormsg = "Unexpected response from API.\n   " + str(response[0]) + "\n   " + str(response[1]['error'])
         if "KeyError" in response[1]['error'] and response[0]['result'] == 'setting auth from data':
            errormsg = errormsg + "\n\nCheck if your API token is correct in the token file.\n   " + config["api_token_file"] + " : " + apitoken
         if response[1]['error'].startswith("No org matching"):
            errormsg = errormsg + "\n\nNote that this error might be caused by using a valid API key for a different organization. Double check that you are using the correct API key."
         usage_abort(extra=errormsg, settings=False)
      else:
         json_data = response[1]['result']
   else:
      if config["log_type"].casefold() == 'ENC'.casefold():
         infile = Path( in_dir, file_prefix_encrypted + '.json' )
      else: 
         infile = Path( in_dir, file_prefix_decrypted + '.json' )
      if not path_accessible( infile ):
         print("Failed to import log (skipping): " + str(infile))
         continue
      else:
         with open(infile, "r") as jsonfile:
            json_data = json.load(jsonfile)
            jsonfile.close()

   if config["log_type"].casefold() == 'ENC'.casefold():
      if config["seccure_decrypt_logs"] == True:
         outfilejson = Path( out_dir, file_prefix_decrypted + '.json' )
         for log in json_data['logs']:
            log['clear'] = json.loads( seccure.decrypt( base64.b64decode( log['enc'] ), passphrase, curve=seccure_curve ) )
      else:
         outfilejson = Path( in_dir, file_prefix_encrypted + '.json' )
   else: 
      outfilejson = Path( out_dir, file_prefix_decrypted + '.json' )
   json_pretty = json.dumps( json_data, indent=4, ensure_ascii=False )
   
   if config["output_console"]:
      print( json_pretty )
      
   if config['output_json']:
      with open (outfilejson, "w") as outfile:
         outfile.write(json_pretty)
      outfile.close()

   if config['output_csv']:
      import csv
      csv_file=open(outfilejson.with_suffix('.csv'),'w', newline='')
      csv_writer = csv.writer(csv_file)
      count = 0
      for record in json_data["logs"]:
         if config["seccure_decrypt_logs"]:
            for key in record["clear"].keys():
               record[key] = record["clear"][key]
            record["clear"] = "TRUE"
         if count==0:
            header = record.keys()
            csv_writer.writerow(header)
            count +=1
         csv_writer.writerow(record.values())
      csv_file.close()
         
