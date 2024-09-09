#!/bin/bash
#Declaring variables


declare DISK_SIZE=1200
if [[ -z "$(grep "disk_size" "/home/$USER/.bashrc")" ]]; then
  echo "disk_size=$DISK_SIZE" >> "/home/$USER/.bashrc"
fi





#########################################################
var="$(python3 -c "print($DISK_SIZE/1000)")G"
disk=$(lsblk | grep "$(python3 -c "print($DISK_SIZE/1000)")G")
echo $var
echo $disk



if [[ -z "$( grep -P "^disk_size=[0-9]+" "/home/$VM_USER/.bashrc")" ]]; then
  echo 'disk_size=$DISK_SIZE' >> '/home/$VM_USER/.bashrc'
  source '/home/$VM_USER/.bashrc'
fi


if [[ -z "$( grep -P "^disk_size=[0-9]+" "/home/$VM_USER/.bashrc")" ]]; then
  echo 'disk_size=$DISK_SIZE' >> '/home/$VM_USER/.bashrc'
  source '/home/$VM_USER/.bashrc'
fi