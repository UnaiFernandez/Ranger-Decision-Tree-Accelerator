# Crear y configurar petalinux

## Crear el projecto

´´´
$ petalinux-create -t project --template zynq -n Ranger_AXI_fifo_test
´´´

## Configurar Petalinux

### Get HW description

´´´
$ petalinux-config --get-hw-description ../../Ranger_zynq-7020/Ranger_AXIS_design_wrapper.xsa
´´´

- **EXT4**
- **Ip addr**

### Kernel config

- **AXI Stream**
- **gcc**

### Rootfs

## Cambiar archivos

## Build

## Package

## dd
