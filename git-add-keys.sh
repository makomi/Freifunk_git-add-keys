# git-add-keys.sh: simple BASH script for bulk adding fastd-keys
# to the given Git repo
# Copyright (C) 2014  Matthias Kolja Miehl
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


#!/usr/bin/env bash

# add a series of keys to the given Git repo
# call: ./git-add-keys.sh <path to file with keys> <path to Git repo>

# format of file with list of keys:
# Line 1: nodename_1 key_1
# Line 2: nodename_2 key_2
# ...
# Line n: nodename_n key_n


# Check for mandatory arguments
# -----------------------------
if [ -z "$2" ]; then
  echo "call: $0 <path to file with keys> <path to Git repo>"
  exit
fi


# Set up environment
# ------------------
WORK_DIR="$(pwd)"

KEY_FILE="$1"
GIT_REPO="$2"

cd "$GIT_REPO"
git pull


# Do the work
# -----------
# get owner
echo -ne "\nProvide the owner's name and email address in the following format.\nOwner name <email address>: "
read -r OWNER

# get node names and respective keys from input file
KEYS=$(cat "$WORK_DIR/$KEY_FILE")
while IFS=" " read -r NODE KEY; do
  # check if new key already exists in the repo
  GREP_OUT=$(grep -Hin "$KEY" .)
  if [ 0 == $? ]; then
    # yes: Does the new node name match the existing file's name?
    # TODO: handle the case of multiple files sharing the same key
    while IFS=":" read -r FILE LINE KEY_TEXT; do
      FILE=$(echo $FILE | sed 's/^..//')
      echo "Exists: $FILE $KEY"
      if [ "$FILE" != "$NODE" ]; then
        # no: update existing file's name to given node name
        echo "Rename: $FILE → $NODE"
        git mv $FILE $NODE
      fi
    done <<< "$GREP_OUT"
  else
    # no: add key to repo
    if [ -e $NODE ]; then
      # it exists a file named like a node in the input file
      # possible filename conflict: file could belong to smbd else → ask user what to do
      # if user selects to update: only change 2nd line of file, i.e. update key
      echo -n "Exists: $NODE – update key? [Y|n] "
      read -r OVERWRITE < /dev/tty
      if [ "n" != "$OVERWRITE" ]; then
        echo "Update: $NODE $KEY"
        sed "2s/.*/key \"$KEY\";/" -i $NODE
      else
        echo "Keep  : $NODE"
      fi
    else
      # file does not exist: create new file
      echo "Add   : $NODE $KEY"
      echo -e "# $OWNER\nkey \"$KEY\";" > "$NODE"
    fi
  fi
done <<< "$KEYS"
