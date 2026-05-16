# SD estable con Buildroot y U-Boot SPL

## Objetivo

El objetivo de esta configuración es generar una imagen SD reproducible para la ZedBoard que arranque Linux y deje cargado el diseño hardware de la PL antes de que el sistema operativo acceda al periférico AXI-Lite. La imagen estable se genera desde Buildroot y queda recogida como artefacto en:

```text
artifacts/buildroot/sdcard.img
```

El flujo validado evita depender de comandos manuales en la consola de U-Boot. Al encender la placa, la SD debe cargar automáticamente el bitstream de Vivado, arrancar Linux y permitir el acceso al periférico en la dirección base `0x40000000`.

## Decisión De Arranque

Durante el desarrollo se probaron dos enfoques de arranque:

```text
BootROM -> FSBL -> bitstream -> U-Boot -> Linux
BootROM -> U-Boot SPL -> u-boot.img -> Linux
```

El flujo con `FSBL` y `BOOT.bin` generado con `bootgen` se conserva como artefacto de diagnóstico, pero no se usa como flujo activo de la SD porque no llegaba a arrancar de forma fiable por UART en las pruebas realizadas.

El flujo estable elegido es:

```text
BootROM -> U-Boot SPL boot.bin -> u-boot.img -> carga de bitstream -> Linux
```

La razón principal es que el arranque con `U-Boot SPL` generado por Buildroot sí demostró arrancar correctamente en la ZedBoard. A partir de ese punto se integró la carga del bitstream dentro del propio `bootcmd` de U-Boot.

## Estructura De La SD

La imagen `sdcard.img` contiene dos particiones:

```text
partition boot   -> FAT
partition rootfs -> ext4
```

La partición `boot` contiene los ficheros necesarios para el arranque:

```text
boot.bin
u-boot.img
uImage
system.dtb
tfg_zedboard_bd_wrapper.bit
extlinux/extlinux.conf
```

El papel de cada fichero es:

- `boot.bin`: primera etapa de arranque generada por U-Boot SPL.
- `u-boot.img`: segunda etapa de U-Boot.
- `uImage`: kernel Linux en formato legacy image.
- `system.dtb`: device tree usado por Linux.
- `tfg_zedboard_bd_wrapper.bit`: bitstream del diseño hardware de Vivado.
- `extlinux/extlinux.conf`: configuración usada por `distro_bootcmd` para arrancar Linux.

La partición `rootfs` contiene el sistema de ficheros raíz generado por Buildroot.

## Configuración Principal De Buildroot

La configuración base del proyecto está en:

```text
sw/buildroot/configs/tfg_zedboard_defconfig
```

Los parámetros principales relacionados con la SD estable son:

```text
BR2_GLOBAL_PATCH_DIR="$(CONFIG_DIR)/../../board/tfg_zedboard/patches"
BR2_ROOTFS_OVERLAY="$(CONFIG_DIR)/../../board/tfg_zedboard/rootfs-overlay"
BR2_ROOTFS_POST_IMAGE_SCRIPT="$(CONFIG_DIR)/../../board/tfg_zedboard/post-image.sh"
BR2_TARGET_UBOOT_CONFIG_FRAGMENT_FILES="$(CONFIG_DIR)/../../board/tfg_zedboard/uboot/bootcmd.config"
```

`BR2_GLOBAL_PATCH_DIR` permite aplicar los parches del device tree para describir el periférico AXI-Lite en Linux.

`BR2_ROOTFS_OVERLAY` reserva una estructura propia para añadir scripts, configuraciones y pruebas al rootfs.

`BR2_ROOTFS_POST_IMAGE_SCRIPT` sustituye el post-image genérico por uno propio del proyecto. Este script prepara la imagen final e incluye el bitstream en la partición `boot`.

`BR2_TARGET_UBOOT_CONFIG_FRAGMENT_FILES` aplica un fragmento de configuración de U-Boot para automatizar la carga del bitstream antes de arrancar Linux.

## Configuración De U-Boot SPL

Buildroot genera U-Boot con soporte SPL mediante:

```text
BR2_TARGET_UBOOT_FORMAT_ELF=y
BR2_TARGET_UBOOT_FORMAT_IMG=y
BR2_TARGET_UBOOT_SPL=y
BR2_TARGET_UBOOT_SPL_NAME="spl/boot.bin"
BR2_TARGET_UBOOT_CUSTOM_MAKEOPTS="DEVICE_TREE=zynq-zed"
```

Con estas opciones se obtienen los artefactos principales:

```text
boot.bin
u-boot.img
u-boot
```

En el repositorio se sincronizan como:

```text
artifacts/buildroot/boot-spl.bin
artifacts/buildroot/u-boot.img
artifacts/buildroot/u-boot.elf
```

## Automatización De La Carga Del Bitstream

Inicialmente la carga de la PL se validó manualmente desde el prompt de U-Boot:

```text
fatload mmc 0:1 0x10000000 tfg_zedboard_bd_wrapper.bit
fpga loadb 0 0x10000000 ${filesize}
boot
```

Esta secuencia funcionó correctamente y permitió comprobar que el periférico respondía desde Linux. Después se automatizó en:

```text
sw/buildroot/board/tfg_zedboard/uboot/bootcmd.config
```

El contenido relevante del fragmento es:

```text
CONFIG_BOOTDELAY=-2
CONFIG_USE_BOOTCOMMAND=y
CONFIG_BOOTCOMMAND="echo Cargando bitstream TFG desde la SD; mmc dev 0; if fatload mmc 0:1 0x10000000 tfg_zedboard_bd_wrapper.bit; then fpga loadb 0 0x10000000 ${filesize}; else echo No se pudo cargar tfg_zedboard_bd_wrapper.bit; fi; run distro_bootcmd"
```

El `bootcmd` realiza cuatro acciones:

- Selecciona la SD con `mmc dev 0`.
- Carga el bitstream desde la partición FAT con `fatload`.
- Programa la PL mediante `fpga loadb`.
- Ejecuta el arranque Linux normal con `run distro_bootcmd`.

El uso de `CONFIG_BOOTDELAY=-2` es intencionado. Con `CONFIG_BOOTDELAY=2`, U-Boot podía quedarse parado en `Zynq>` si la UART recibía algún carácter durante la cuenta atrás. Con `-2`, U-Boot ejecuta directamente `bootcmd` y la SD arranca sin intervención manual.

## Device Tree Y Dirección Del Periférico

El bitstream configura físicamente la PL, pero Linux también necesita conocer la existencia del periférico. Para ello se aplican parches al device tree del kernel usado por Buildroot.

El nodo del periférico queda descrito como:

```text
tfg_axi_lite_regs@40000000
compatible = "tfg,tfg-axi-lite-regs-1.0"
reg = <0x40000000 0x1000>
```

La dirección base coincide con la asignada en Vivado:

```text
0x40000000
```

El rango usado es:

```text
0x1000
```

Sin cargar el bitstream, acceder a `0x40000000` puede bloquear el sistema porque el bus AXI no encuentra el esclavo en la PL. Por eso la carga del bitstream antes de Linux es parte fundamental de la SD estable.

## Generación Reproducible

La configuración del proyecto se carga con:

```bash
./sw/buildroot/scripts/build_buildroot.sh project-defconfig
```

Si se cambia configuración de U-Boot, se fuerza la regeneración de U-Boot con:

```bash
./sw/buildroot/scripts/build_buildroot.sh uboot-reconfigure
```

La imagen completa se regenera con:

```bash
./sw/buildroot/scripts/build_buildroot.sh
```

Y los artefactos finales se sincronizan con:

```bash
./sw/buildroot/scripts/sync_buildroot_artifacts.sh
```

El artefacto final a grabar en la SD es:

```text
artifacts/buildroot/sdcard.img
```

## Avisos Conocidos Del Arranque

Durante el arranque aparecen algunos avisos que no bloquean el flujo validado.

U-Boot muestra:

```text
Loading Environment from FAT... *** Error - No Valid Environment Area found
*** Warning - bad env area, using default environment
```

Esto significa que U-Boot intenta cargar un entorno persistente desde FAT, pero no encuentra uno válido. En este proyecto no es un problema porque las variables importantes (`bootcmd` y `bootdelay`) están compiladas dentro de `u-boot.img` mediante `bootcmd.config`.

SPL también muestra:

```text
spl_load_image_fat: error reading image uImage, err - -22
```

Este mensaje no impide el arranque en el flujo actual. Tras ese aviso, SPL carga `u-boot.img` y U-Boot continúa normalmente.

Durante la carga del bitstream aparece:

```text
INFO:post config was not run, please run manually if needed
```

Este aviso tampoco bloquea la configuración de la PL en esta prueba. La evidencia es que Linux arranca y el periférico AXI-Lite responde correctamente.

## Evidencia De Validación

En el arranque estable aparece:

```text
Cargando bitstream TFG desde la SD
4045683 bytes read
design filename = "tfg_zedboard_bd_wrapper;UserID=0XFFFFFFFF;Version=2022.2"
part number = "7z020clg484"
```

Después U-Boot ejecuta `distro_bootcmd`, carga `extlinux/extlinux.conf`, recupera `uImage` y `system.dtb`, y arranca Linux.

La comprobación final desde Linux es:

```text
devmem 0x40000000
```

Resultado obtenido:

```text
0x54464700
```

Este valor confirma que la PL está cargada y que el periférico AXI-Lite responde en la dirección base esperada.

## Resultado Final

La SD estable queda definida como una imagen Buildroot reproducible que:

- Arranca mediante `U-Boot SPL`.
- Carga automáticamente el bitstream desde la partición `boot`.
- Arranca Linux mediante `extlinux`.
- Usa un device tree con el nodo del periférico AXI-Lite.
- Permite acceder correctamente al periférico en `0x40000000`.

Esta configuración es la base estable para las siguientes pruebas software sobre el periférico.
