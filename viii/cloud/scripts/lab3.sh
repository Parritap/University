#!/bin/bash

#Abstracción -> Qué se quiere hacer?
#   - Crear y formatear disco nuevo (vdi), crearle una particion entera
#   - definimos punto de montaje en el guestOS de manera que sea funcional
#   - (extra) crear un archivo y escribir la fecha y hora del sistema dentro del mismo for testing porpuses

#Parameters 1-> vm_name/UUID -> Then will have to search where said machine is located to put the disk there.
#           2-> disk_size
#           3->

#NOTAS: En este script asumimos que la VM posee las Guest Additions instaladas.
#       Esto nos permitirá hacer uso de un comando que permite ejecutar scripts en la maquina guest.

#variable declaration

declare -r VM_NAME=$1
declare -r DISK_NAME=$2
declare -r DISK_SIZE=$3
declare -r VM_USER=$4
declare -r VM_PASS=$5
declare space_in_g=""

## This is a String that contains the script that will be executed in the guest machine
## The values of the variables are substituted in the script
# The following DOES NOT TAKE IN COUNT THE PRESENT VARAIBLES but GUEST_OS VARIABLES.
#declare guest_script=$(cat <<'EOF'
#disk=$(lsblk | grep "$(python3 -c "print($DISK_SIZE/1000)")G") #Greps the disk that has the size of the disk we want to format
#EOF
#)

#The following DOES TAKE IN COUNT THE PRESENT VARAIBLES

#Guest disk_size variable should be filles only with numbers, the MB quantity.
guest_script="
if grep -q "^export disk_size=" "/home/$VM_USER/.bashrc"; then
  # Replace the existing export disk_size value
  sed -i "s/^export disk_size=.*/export disk_size=$DISK_SIZE/" "/home/$VM_USER/.bashrc"
else
  # Add export disk_size if it doesn't exist
  echo "export disk_size=$DISK_SIZE" >> "/home/$VM_USER/.bashrc"
fi

# Reload the .bashrc to apply changes
source "/home/$VM_USER/.bashrc"

#Now execute the script that is in the guestOS
bash /home/$VM_USER/scripts/format_disk.sh
"


declare DISK_DIR=""

if [[ -z $VM_NAME ]]; then echo "ERROR: NO VM NAME SPECIFIED..... ABORTING"; exit 1; fi
if [[ -z $DISK_NAME ]]; then echo "ERROR: NO DISK NAME SPECIFIED..... ABORTING"; exit 1; fi
if [[ -z $DISK_SIZE ]]; then echo "ERROR: NO DISK SIZE SPECIFIED..... ABORTING"; exit 1; fi
if [[ -z $VM_USER ]]; then echo "ERROR: NO VM USER SPECIFIED..... ABORTING"; exit 1; fi
if [[ -z $VM_PASS ]]; then echo "ERROR: NO VM PASSWORD SPECIFIED..... ABORTING"; exit 1; fi

#Check if the VM exists
if ! VBoxManage list vms | grep -q "\"$VM_NAME\""; then
    echo "ERROR: VM $VM_NAME DOES NOT EXIST..... ABORTING"
    exit 1
fi

#Check if disk size is a number and is greater than 0
if ! [[ $DISK_SIZE =~ ^[0-9]+$ ]]; then
    echo "ERROR: DISK SIZE MUST BE A NUMBER..... ABORTING"
    exit 1
fi

space_in_g=$(python3 -c "print($DISK_SIZE/1000)")


#This function checks for where the vm is located "CfgFile" and then extracts the path to the directory
function set_disk_dir () {
  val=$(vboxmanage showvminfo "$VM_NAME" --machinereadable | grep "CfgFile" | cut -d "=" -f 2)
  val=$(echo $val | sed 's/^"//;s/"$//')
  val="${val%/*}"
  val=$(correct_path "$val")
  echo "$val/"
}

#Since VirtualBox paths can contain spaces, we need to handle them correctly
function clean_path() {
    # Split the path into components using IFS (Internal Field Separator)
    IFS='/' read -ra path_components <<< "$1"

    # Reconstruct the path with quotes around directories that contain spaces
    clean_path=""
    for component in "${path_components[@]}"; do
        if [[ "$component" =~ \  ]]; then
            # Add quotes around components that contain spaces
            clean_path+="'$component'/"
        else
            clean_path+="$component/"
        fi
    done

    # Remove the trailing slash if needed (optional)
    clean_path=${correct_path%/}
    echo "$correct_path"
}


# Now lets create a new vdi disk using createmedium
# We will use the path of the vm to create the disk in the same directory
#DISK_DIR=$(set_disk_dir)
#vboxmange createmedium disk --filename "$DISK_DIR/$DISK_NAME.vdi" --size $DISK_SIZE --format VD

#Now lets start the VM
##vboxmanage startvm "$VM_NAME" --type gui
##sleep 12s
#"$(cat $guest_script)"
vboxmanage guestcontrol "$VM_NAME" run --exe "/bin/bash" --username $VM_USER --password $VM_PASS  --wait-stdout --wait-stderr -- -c "$(echo "$guest_script")"


