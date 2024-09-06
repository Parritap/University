#!/bin/bash

#variable declaration
declare network_adapter

# Function declaration
get_val() {
  val=$(grep "$1:" "$file" | cut -d':' -f2)

  if [[ -z $val ]]; then
    echo "ERROR: NO VALUE EXISTS FOR PROPERTY '$1'....... ABORTING"
    exit 1
  else
    echo $val
  fi
}

set_net_adapter() {
  network_adapter=$(nmcli device status | grep 'connected' | grep -v 'disconnected' | grep -v '\-\-' | grep -v 'lo')
  if [[ -z ]]
}



eval_net_adapter() {
  val=$(grep "$1:" "$file" | cut -d':' -f2) 

  if [[ "$1" == "network_adapter" && -n "$val" ]]; then
    echo "network_adapter value is empty"
  else 
    set_net_adapter()
  fi
 }


# Variables declaration
file=$1

if [[ ! -f $file ]]; then
  echo "ERROR: FILE '$file' does not exist"   >&2
  exit 1
fi

vm_name=$(get_val "vm_name")
ostype=$(get_val "ostype")
mem=$(get_val "mem")
disk_space=$(get_val "disk_space")
network_adapter=$(get_val "network_adapter")
bridged_adapter=$(get_val "bridged_adapter")
graphics_controller=$(get_val "graphics_controller")
vmem=$(get_val "vmem")

# ERROR HANDLING
#
#


