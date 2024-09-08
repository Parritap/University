#!/bin/bash

#Este script facilita la creación y administración de dos VMs en VirtualBox,
# gestionando también el disco virtual. Permite seleccionar dinámicamente cuál
# de las dos máquinas utilizará un disco compartido, simplificando la tarea de
# configurar y modificar máquinas virtuales desde la terminal.


#---------------------------------------------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------------------------------------


# Se usa getopts para manejar las opciones -n (nombre de la VM) y -d (ruta del disco duro).
# La opción -n asigna un nombre a VM1_NAME si está vacío, y si ya tiene un valor, lo asigna a VM2_NAME.
# La opción -d especifica la ruta del archivo de disco virtual.
# Si se ingresa una opción inválida, muestra un mensaje de error y termina el script.

while getopts ":n:d:" opcion
do
	case $opcion in
		n)
			if [[ -z $VM1_NAME ]]; then VM1_NAME="$OPTARG"; fi
			if [[ -n $VM1_NAME ]]; then VM2_NAME="$OPTARG"; fi
			;;
		d)
			DISK_PATH="$OPTARG"
			;;
		*)
			echo "Opcion invalida, -$OPTARG"
			echo "utiliza las opciones: -d (disk_path) o -n (vm_name)"
			exit
			;;

	esac

done





# Se verifica si VM1_NAME o VM2_NAME ya existen usando VBoxManage list vms.
# Si la VM no existe, se crea con VBoxManage createvm y se configura con VBoxManage modifyvm para asignar 1024 MB de RAM y 128 MB de memoria de video.

if ! VBoxManage list vms | grep -q "\"$VM1_NAME\""; then
    VBoxManage createvm --name "$VM1_NAME" --ostype "Ubuntu_64" --register
    VBoxManage modifyvm "$VM1_NAME" --memory 1024 --vram 128
fi

if ! VBoxManage list vms | grep -q "\"$VM2_NAME\""; then
    VBoxManage createvm --name "$VM2_NAME" --ostype "Ubuntu_64" --register
    VBoxManage modifyvm "$VM2_NAME" --memory 1024 --vram 128
fi




#buscar version actualizada de createhd
if [ ! -f "$DISK_PATH" ]; then
    VBoxManage createhd --filename "$DISK_PATH" --size 10000
fi

# adjuntar_disco: adjunta el disco especificado en DISK_PATH a la VM indicada como parámetro.
adjuntar_disco() {
    VM_NAME=$1
    echo "Adjuntando disco a $VM_NAME"
    VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --port 1 --device 0 --type hdd --medium "$DISK_PATH"
}


# desadjuntar_disco: desadjunta cualquier disco conectado a la VM especificada.
# Si el archivo de disco especificado en DISK_PATH no existe, se crea un nuevo disco virtual de 10 GB usando VBoxManage createhd.
desadjuntar_disco() {
    VM_NAME=$1
    echo "Desadjuntando disco de $VM_NAME"
    VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --port 1 --device 0 --type hdd --medium none
}


# Se le pregunta al usuario cuál de las dos VMs debería usar el disco.
# Primero, se desadjunta el disco de ambas VMs (en caso de que esté adjuntado a alguna).
# Dependiendo de la elección del usuario, se adjunta el disco a la VM seleccionada.
# Si la elección no es válida, se muestra un mensaje y no se realiza ningún cambio.
# echo "¿Qué VM debería usar el disco? Ingresa 1 para VM1 o 2 para VM2:"
# read VM_CHOICE


desadjuntar_disco "$VM1_NAME"
desadjuntar_disco "$VM2_NAME"


if [ "$VM_CHOICE" -eq 1 ]; then
    adjuntar_disco "$VM1_NAME"
elif [ "$VM_CHOICE" -eq 2 ]; then
    adjuntar_disco "$VM2_NAME"
else
    echo "Elección no válida. No se hicieron cambios."
fi
