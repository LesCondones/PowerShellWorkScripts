#!/bin/bash

# Directory containing the dump files
DUMP_DIR="edbas/recover/bupg_dir/dumpall"

#Loop through each dumop file in the directory
for dump_file in "$DUMP_DIR"/*.dmp; do
  # extract the base name of the file (without directory and extension)
  base_name=$(basename "$dump_file" .dmp)

  #Remove the date part from the base name to get the databse name
  db_name=$(echo "base_name")

  log_file="/var/lib/barman/script/${db_name}_restore.log"

  #Create the database if it doesnt exist
  createdb "$db_name"

  # restore database from the dump file
  nohup pg_restore -U barman -d "$db_name" -v "$dump_file" >> "$log_file" 2>&1 & disown

  # check if the restore was successful
  if [$? -eq 0]; then 
      echo "Successfuly restored $db_name FROM $dump_file"
  else
      echo "Failed to restore $db_name from $dump_file
  fi
done
