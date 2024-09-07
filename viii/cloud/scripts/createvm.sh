#!/bin/bash

#Variables declaration
declare network_adapter="" #Like an enum, possible values are [none|null|nat|natnetwork|bridged|intnet|hostonly|generic]
declare bridged_adapter="" #i.e the host NIC that is goint to be bridged wit the VM.
declare -r file=$1 #First arg is the YAML file where the VM info is in. 
declare disk_dir="" #The directory where the VM's volume is going to be stored.


#Gets the value of of the specified key in a YAML file.
#This function should only have one param which is the key from "key:value" pair.
get_val() {
  val=$(grep -P "^$1:.*" "$file" | cut -d':' -f2 | sed 's/ //g')

  if [[ -z "$val" ]]; then
    echo "ERROR: NO VALUE EXISTS FOR PROPERTY '$1'....... ABORTING"
    exit 1
  else
    echo "$val"
  fi
}

#WORKS ONLY FOR LINUX
#Sets the bridged adapter to one that is connected and has a valid internet connection. 
#If both conditions mentioned are not met, then it sets any NIC that isnt loop-back
set_bridged_adapter() {
  bridged_adapter=$(nmcli device status | grep " connected" | grep -v "lo" | grep -v '\-\-' 2> /dev/null | awk '{print $1}')
  if [[ -z $bridged_adapter ]]; then
    echo "THERE IS NO NETWORK INTERFACE CONNECTED WITH VALID A CONNECTION"
    #The next line sets any other network adapter that isnt loopback
    bridged_adapter="$(nmcli device status | grep -v "lo" | grep -v "DEVICE" | head -n 1 | grep -oE "^[a-zA-Z0-9]+")"
  fi
  echo "USING GUEST NETWORK ADAPTER: $bridged_adapter " 
}


# Evalutes which mode is going to be set for vm's nic1.
# For now, this script only allows to the user to set up one vm nic. 
eval_net_adapter_type() {
  val=$(grep "network_adapter:" "$file" | cut -d':' -f2) 
  network_adapter=$(echo "$val" | sed 's/ //g') #This line cleans all white spaces.

  ##Por ahora solo hay una posibilidad
  if [[ -n "$network_adapter" ]]; then #Checks if network adapter is not empty
    case "$network_adapter" in
      "bridged")
      set_bridged_adapter
      ;;
    esac
    else  
      echo "Network adapter is not specified or is not valid"
  fi
}

eval_disk_dir() {
  val="$(get_val "disk_dir")"
  disk_dir=$(echo "$val" | sed 's/ //g')
  if [[ -n "$disk_dir" && "$disk_dir" -gt 0 ]]; then #This line checks that the volume_dir is not empty and is greater than 0
    echo "$disk_dir"
  else  
    #In case that no volume_dir is specified, the following is going to be used as default.
    echo "/home/$USER/VirtualBox VMs/$vm_name/${vm_name}_disk.vdi"
  fi
}

##################################################################################################
################################################ Main ############################################
##################################################################################################

#1) First:
# Check if YAML file does exist, if not, no vm can be created, so execution is aborted. 
if [[ ! -f $file ]]; then
  echo "ERROR: FILE $(file) does not exist" >&2
  exit 1
fi

#2) Second:
# Get all the values from the YAML file
vm_name=$(get_val "vm_name")
ostype=$(get_val "ostype")
mem=$(get_val "mem")
cores=$(get_val "cores")
disk_space=$(get_val "disk_space")
disk_dir=$(eval_disk_dir)
graphics_controller=$(get_val "graphics_controller")
vmem=$(get_val "vmem")
iso=$(get_val "iso")

#3) Third:
#Checking if a valid iso is specified
if [[ -z "$iso" ]]; then
  echo "ERROR: NO ISO FILE SPECIFIED..... ABORTING"
  elif [[ ! -f "$iso" ]]; then
    echo "ERROR: FILE $iso DOES NOT EXIST..... ABORTING"
  exit 1
fi

# 4) Fourth:
#Handling network adapter mode
eval_net_adapter_type



#Print all existing variables for debugging purposes
echo "VM NAME: $vm_name"
echo "OS TYPE: $ostype"
echo "MEM: $mem"
echo "CORES: $cores"
echo "DISK SPACE: $disk_space"
echo "GRAPHICS CONTROLLER: $graphics_controller"
echo "VMEM: $vmem"
echo "NETWORK ADAPTER: $network_adapter"
echo "BRIDGED ADAPTER: $bridged_adapter"
echo "VOLUME DIR: $disk_dir"  



####################################### Creating the virtual machine #####################################!/usr/bin/env bash

# Crear la máquina virtual
vboxmanage createvm --name "$vm_name" --ostype "$ostype" --register

# Configurar la memoria RAM, memoria de video, CPUs y habilitar IOAPIC
vboxmanage modifyvm "$vm_name" --memory "$mem" --vram "$vmem" --cpus "$cores" --ioapic on

# Configurar la red como Adaptador Puente 
# TODO: Agregar más opciones 
if [[ "$network_adapter" == "bridged" ]]; then
  vboxmanage modifyvm "$vm_name" --nic1 bridged --bridgeadapter1 "$bridged_adapter"
fi

# Configurar el controlador SATA y crear un disco duro de 25 GB
vboxmanage storagectl "$vm_name" --name "SATA Controller" --add sata --controller IntelAhci
vboxmanage createmedium --filename "$disk_dir" --size "$disk_space"
vboxmanage storageattach "$vm_name" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$disk_dir"

# Agregar el controlador IDE para el disco óptico e insertar la imagen ISO
vboxmanage storagectl "$vm_name" --name "IDE Controller" --add ide
vboxmanage storageattach "$vm_name" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$iso"

# Configurar el controlador de video y habilitar EFI
vboxmanage modifyvm "$vm_name" --graphicscontroller "$graphics_controller" --firmware efi --boot1 dvd --boot2 disk --boot3 none --boot4 none

# Setting up the boot order
vboxmanage modifyvm "$vm_name" --boot1 dvd --boot2 disk

vboxmanage modifyvm "$vm_name" --firmware efi  
