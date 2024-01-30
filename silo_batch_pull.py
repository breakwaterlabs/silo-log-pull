#!/usr/bin/env python

from getopt import getopt # Old school to support Python < 2.7
import json
import os
import sys
from datetime import date
from datetime import timedelta
import re

settings_path = "silo_config.json"
default_settings = {
   "ea_host" : 'extapi.authentic8.com',
   "customer_org" : "",
   "token_file_path" : "token.txt",
   "log_type" : 'ENC',
   "fetch_num_days" : 7,
   "output_directory" : "logs",
   "output_csv" : True,
   "output_json" : False,
   "output_console": True,
   "download_logs": False,
   "decrypt_logs" : True,
   "decrypt_passphrase_file": "seccure_key.txt",
   "display_seccure_pubkey": False
}

def usage_abort( extra='', settings=True ):
   print("####################################################################")
   print("########################### FATAL ERROR ############################")
   print("####################################################################")
   if settings:
      print("\nMissing, incorrect, or invalid settings or files. The following settings are required in " + settings_path)
      print('   "customer_org" : "<org>"')
      print("\nIf decrypt_logs or display_seccure_pubkey is True, then the following setting must be set to a file containing the seccure passphrase: ")
      print('   "decrypt_passphrase_file" : "<seccure_key.txt>" ')
   else:
      print("\nSomething went wrong unrelated to reading your settings.")
      print("\nThis is probably an issue with either the Authentic8 API endpoint, or your API key / Org name.")
   print("\nPlease see below for any specific error details:\n\n")
   print(extra)
   input("\nPress any key to exit...")
   sys.exit()

def create_settings_file(path, settings):
   try:
      os.rename(path, path + ".bak")
      with open(path, "w") as jsonfile:
         jsonfile.write( json.dumps(settings, indent=4))
         jsonfile.close()
      print("Wrote settings file at " + path)
   except:
      usage_abort("Could not create a backup of your settings at:\n  " + path + ".bak\n" + "\nEither fix your current settings file or delete the existing backup.", settings=False )

def path_accessible(path, as_dir=False):
   if as_dir:
      return os.path.isdir(path) and os.access(path, os.R_OK)
   else:
      return os.path.isfile(path) and os.access(path, os.R_OK)

def import_json_config(config_path, defaults):
   if path_accessible(config_path):
      print("Settings file found. Importing settings.")
      with open(config_path, "r") as jsonfile:
         try:
            file_config = json.load(jsonfile)
         except:
            usage_abort("Could not parse settings file as valid JSON. Either fix the file, rename it, or delete it and this script will create a new one.")
         jsonfile.close()
   else:
      create_settings_file(config_path, defaults)
      usage_abort("Settings file was not found, so created new at " + config_path + ". Please set customer_org in this file before re-running.")
   if file_config.get("customer_org") is None:
      usage_abort( 'customer_org must be defined.' )
   elif not (type(file_config["customer_org"]) == type(defaults["customer_org"])):
      usage_abort( 'Wrong type for customer_org. Expecting ' +  type(defaults["customer_org"]) )
   elif file_config["customer_org"] == "":
      usage_abort( 'customer_org must not be blank.' )
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
   if bad_settings:
      print("\n\n!! Some bad settings detected, so defaults were used. Please check that these are correct.")
      input("\nPress any key to continue, and create a fixed config file. A backup of your config file will be made.")
      create_settings_file(config_path, file_config)
   return file_config

config = import_json_config(settings_path, default_settings)

if config["decrypt_logs"] or config["display_seccure_pubkey"]:
   import seccure
   import base64
   if not config["decrypt_passphrase_file"] or not path_accessible(config["decrypt_passphrase_file"]):
      usage_abort("could not access the decrypt_passphrase_file: " + config["decrypt_passphrase_file"])
   pass_file = open( config["decrypt_passphrase_file"], "rb" )
   passphrase = pass_file.read().rstrip()
   pass_file.close()
   if len(passphrase) < 1:
      usage_abort("Your passphrase file is empty. Please make sure you have specified a passphrase.")
   if len(passphrase) < 10:
      input("\nYour passphrase is very short. Please make a new passphrase that meets NIST recommendations.")
   if config["display_seccure_pubkey"]:   
      input("\n-----  Start Seccure Pubkey  -----\n" + str(seccure.passphrase_to_pubkey(passphrase))+ "\n------  End Seccure Pubkey  ------\n\n")

out_dir = re.sub(r'[^\w_. -]', '_', config["output_directory"])

if not path_accessible(out_dir, True):
   os.makedirs(out_dir)
if not path_accessible(out_dir, True):
   usage_abort("Missing output directory / failed to create: " + out_dir)

if config["download_logs"]:
   import urllib.request, urllib.error, urllib.parse
   import base64
   cmd = {
      'command': 'extractlog',
      'org': config["customer_org"],
      'type': config["log_type"]
   }
   if not (config.get("limit") is None):
      cmd['limit'] = config["limit"]
   if not path_accessible(config["token_file_path"]):
      usage_abort("token_file_path is not accessible")
   token_file = open( config["token_file_path"], 'r' )
   apitoken = token_file.read().strip()
   if not (base64.b64encode(base64.b64decode(apitoken)).decode('ascii') == apitoken and len(apitoken) == 32):
      usage_abort( "Check your API token. It should be 32 characters long in base64.\n"+ config["token_file_path"] + " : " + apitoken)
   auth_cmd = {
      'command': 'setauth',
      'data': apitoken}
   token_file.close()
   url = 'https://' + config["ea_host"] + '/api/'
   headers = { 'Content-Type': 'application/json' }

for i in range(config["fetch_num_days"]):
   this_day = (date.today() - timedelta(days=i)).strftime('%Y-%m-%d')
   this_day_start = this_day + " 00:00:00"
   this_day_end = this_day + " 23:59:59"
   print("Date range: " + this_day_start + " - " + this_day_end)
   
   file_prefix_encrypted = out_dir + '\silo_encrypted_' + this_day
   file_prefix_decrypted = out_dir + '\silo_decrypted_' + this_day
   if config["download_logs"]:
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
            errormsg = errormsg + "\n\nCheck if your API token is correct in the token file.\n   " + config["token_file_path"] + " : " + apitoken
         if response[1]['error'].startswith("No org matching"):
            errormsg = errormsg + "\n\nNote that this error might be caused by using a valid API key for a different organization. Double check that you are using the correct API key."
         usage_abort(extra=errormsg, settings=False)
      else:
         json_data = response[1]['result']
   else:
      if config["decrypt_logs"]:
         infile = file_prefix_encrypted + '.json'
      else: 
         infile = file_prefix_decrypted + '.json'
      if not path_accessible( infile ):
         usage_abort("Settings indicate local import instad of download, but could not access local log: " + infile)
      with open(infile, "r") as jsonfile:
         json_data = json.load(jsonfile)
         jsonfile.close()

   if config["decrypt_logs"]:
      for log in json_data['logs']:
         log['clear'] = json.loads( seccure.decrypt( base64.b64decode( log['enc'] ), passphrase, curve='secp256r1/nistp256' ) )
      outfile_prefix = file_prefix_decrypted
   else:
      outfile_prefix = file_prefix_encrypted
   json_pretty = json.dumps( json_data, indent=4, ensure_ascii=False )
   
   if config["output_console"]:
      print( json_pretty )
      
   if config['output_json']:
      with open (outfile_prefix + '.json', "w") as outfile:
         outfile.write(json_pretty)
      outfile.close()

   if config['output_csv']:
      import csv
      csv_file=open(outfile_prefix + '.csv','w', newline='')
      csv_writer = csv.writer(csv_file)
      count = 0
      for record in json_data["logs"]:
         if config["decrypt_logs"]:
            for key in record["clear"].keys():
               record[key] = record["clear"][key]
            record["clear"] = "TRUE"
         if count==0:
            header = record.keys()
            csv_writer.writerow(header)
            count +=1
         csv_writer.writerow(record.values())
      csv_file.close()
         
