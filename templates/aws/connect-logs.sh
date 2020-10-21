#!/bin/bash

##========================================================================================
## DESCRIPTION: Script to tail the logs from a kafka-connect server (or any other really)
## AUTHOR: Sam Beckett (@sbeck14)
##========================================================================================

# m4_ignore(
  echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
  exit 11  
#)
# ARG_OPTIONAL_SINGLE([filepath], [f], [Path to the file to tail on the server], [/var/log/kafka/kafka-connect.out])
# ARG_OPTIONAL_SINGLE([sshkey], [i], [Path to the SSH key to use for authentication], [~/.ssh/ops.pem])
# ARG_OPTIONAL_SINGLE([lines], [n], [How many lines to tail], [10000])
# ARG_POSITIONAL_SINGLE([server], [Endpoint of the server to connect to])
# ARG_DEFAULTS_POS
# ARG_HELP([connect-logs], [Fetch the latest logs for kafka connect])
# ARGBASH_GO

# [ <-- needed because of Argbash

ssh -i $_arg_sshkey ec2-user@$_arg_server "tail $_arg_filepath -n $_arg_lines"

# ] <-- needed because of Argbash
