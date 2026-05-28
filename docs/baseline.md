# Baseline del proyecto

- Fecha de creación: 2026-04-20
- Raíz del proyecto: `tfg_zedboard`
- Estado: `T11` completada

## Plataforma

- Placa objetivo: `Digilent ZedBoard`
- SoC: `XC7Z020-CLG484-1`
- Estrategia de arranque: `SD`

## Versiones congeladas

- Vivado: `2022.2`
- Vitis: `2022.2`
- Ubuntu host real: `Ubuntu 20.04.6 LTS`
- Buildroot congelado: `2023.02.9`

## Nombres congelados

- Nombre del proyecto Vivado: `tfg_zedboard`
- Nombre del IP AXI-Lite: `tfg_axi_lite_regs`

## Estado de especificación del IP

- `T2` cerrada a nivel de contrato HW/SW.
- Directorio físico del IP empaquetado: `hw/ip/tfg_axi_lite_regs_1_0/`
- Especificación del IP: `hw/ip/tfg_axi_lite_regs_1_0/spec.md`
- Header de software asociado: `sw/include/tfg_axi_lite_regs.h`

## Estado de integración hardware

- `T4` cerrada a nivel de proyecto Vivado y Block Design base.
- Proyecto Vivado: `hw/vivado/tfg_zedboard/tfg_zedboard.xpr`
- Nombre del Block Design: `tfg_zedboard_bd`
- Preset de placa aplicado en PS: `ZedBoard`
- Puerto AXI habilitado en PS: `M_AXI_GP0`
- Reloj PL utilizado: `FCLK_CLK0 = 100 MHz`
- Reset de sistema: `proc_sys_reset`
- Dirección base del IP en `Address Editor`: `0x40000000`
- Rango asignado al IP en `Address Editor`: `0x1000` (`4K`)
- Wrapper HDL del Block Design: generado

## Estado de implementación hardware

- `T5` cerrada a nivel de bitstream y exportación hardware.
- Bitstream final: `artifacts/hw/tfg_zedboard_bd_wrapper.bit`
- Exportación hardware final: `artifacts/hw/tfg_zedboard.xsa`
- Informes principales conservados en:
  - `artifacts/hw/reports/`

## Estado de arranque

- `T6` cerrada a nivel de generación de `FSBL` y empaquetado de `BOOT.bin`, pero el flujo activo de SD vuelve a ser `U-Boot SPL`.
- Script XSCT del `FSBL`: `sw/vitis/scripts/create_fsbl.tcl`
- Script de ejecución del `FSBL`: `sw/vitis/scripts/run_create_fsbl.sh`
- Script de empaquetado final: `sw/vitis/scripts/generate_boot_bin.sh`
- `FSBL` final: `artifacts/boot/fsbl.elf`
- Fichero `BIF` generado: `artifacts/boot/tfg_zedboard_boot.bif`
- `BOOT.bin` final: `artifacts/boot/BOOT.bin`
- Composición del `BOOT.bin`:
  - `fsbl.elf`
  - `tfg_zedboard_bd_wrapper.bit`
  - `u-boot.elf`
- Nota: el `BOOT.bin` FSBL se conserva como artefacto de diagnóstico; no es el primer cargador usado por la `sdcard.img` activa.

## Estado de Buildroot

- `T7` cerrada a nivel de build base reproducible.
- Versión usada: `Buildroot 2023.02.9`
- Árbol fuente: `sw/buildroot/buildroot-2023.02.9/`
- Defconfig propia del proyecto: `sw/buildroot/configs/tfg_zedboard_defconfig`
- Directorio de salida out-of-tree: `sw/buildroot/output/zedboard/`
- Script de invocación: `sw/buildroot/scripts/build_buildroot.sh`
- Artefactos principales congelados en `artifacts/buildroot/`
- Flujo de arranque activo: `BootROM -> U-Boot SPL -> u-boot.img -> Linux`
- Primer cargador activo: `artifacts/buildroot/boot-spl.bin`
- Segunda etapa de U-Boot activa: `artifacts/buildroot/u-boot.img`
- U-Boot ELF conservado como artefacto auxiliar: `artifacts/buildroot/u-boot.elf`
- Bitstream disponible en la partición `boot`: `artifacts/buildroot/tfg_zedboard_bd_wrapper.bit`
- Carga de bitstream validada manualmente desde U-Boot con `fpga loadb`
- Carga de bitstream automatizada en U-Boot mediante `sw/buildroot/board/tfg_zedboard/uboot/bootcmd.config`
- Autoboot configurado con `CONFIG_BOOTDELAY=-2` para evitar parada accidental en `Zynq>`
- Documento de referencia del flujo SD estable: `docs/boot/sd-estable-buildroot-uboot.md`
- Kernel generado: `artifacts/buildroot/uImage`
- DTB actual: `artifacts/buildroot/system.dtb`
- Root filesystem base: `artifacts/buildroot/rootfs.ext4`
- Imagen SD estable generada por Buildroot: `artifacts/buildroot/sdcard.img`
- Acceso validado al periférico tras cargar la PL: `devmem 0x40000000 -> 0x54464700`

## Estado de device tree y rootfs

- `T8` cerrada a nivel de descripción hardware Linux y preparación del rootfs base.
- Directorio de personalización de placa: `sw/buildroot/board/tfg_zedboard/`
- Parcheo del kernel activado con `BR2_GLOBAL_PATCH_DIR`
- Nodo del periférico descrito en: `sw/buildroot/board/tfg_zedboard/dts/tfg-zedboard-axi-lite-regs.dtsi`
- Integración del nodo en `zynq-zed.dts` mediante parches de Buildroot
- Nodo validado en el `dtb` final:
  - `compatible = "tfg,tfg-axi-lite-regs-1.0"`
  - `reg = <0x40000000 0x1000>`
  - `clock-names = "s_axi_aclk"`
- Overlay reservado en: `sw/buildroot/board/tfg_zedboard/rootfs-overlay/`
- Estructura prevista del rootfs personalizada para configuración, scripts y pruebas del TFG

## Estado de SD estable

- `T9` cerrada a nivel de imagen SD estable.
- Flujo activo: `BootROM -> U-Boot SPL -> u-boot.img -> carga automática del bitstream -> Linux`
- Script post-image propio: `sw/buildroot/board/tfg_zedboard/post-image.sh`
- Configuración genimage propia: `sw/buildroot/board/tfg_zedboard/genimage.cfg`
- Fragmento U-Boot propio: `sw/buildroot/board/tfg_zedboard/uboot/bootcmd.config`
- Documento de referencia: `docs/boot/sd-estable-buildroot-uboot.md`
- Imagen SD estable: `artifacts/buildroot/sdcard.img`
- Validación en placa: `devmem 0x40000000 -> 0x54464700`

## Estado de utilidad Linux

- `T10` cerrada a nivel de utilidad de usuario para acceso y medida con `/dev/mem`.
- Utilidad principal: `sw/linux-tests/tfg_axi_memtool.c`
- Compilación: `make -C sw/linux-tests`
- Toolchain por defecto: `sw/buildroot/output/zedboard/host/bin/arm-buildroot-linux-gnueabihf-gcc`
- Acceso físico usado: `/dev/mem` con `O_RDWR | O_SYNC` y `mmap`
- Dirección base por defecto: `0x40000000`
- Ventana mapeada por defecto: `0x1000`
- Comprobación previa: `REG_ID == 0x54464700`
- Modos implementados: `smoke`, `read`, `write`, `read-loop`, `write-loop`, `rw-loop`
- Salida de medidas: texto estructurado o CSV
- Despliegue elegido: `rootfs-overlay`
- Script de instalación en overlay: `sw/linux-tests/install_to_rootfs_overlay.sh`
- Ruta final en target: `/usr/local/bin/tfg_axi_memtool`
- Evidencia funcional: `smoke` y medidas `rw-loop` validadas sobre la SD estable.
- `PATH` del sistema configurado para incluir `/usr/local/bin` al arrancar, vía `sw/buildroot/board/tfg_zedboard/rootfs-overlay/etc/profile.d/tfg-path.sh`.

## Estado de campañas de medida

- `T11` cerrada a nivel de automatización de campañas y estructura de captura.
- Script principal en repositorio: `measurements/t11/run_rw_campaign.sh`
- Script instalado en target mediante overlay: `/usr/local/bin/run_rw_campaign.sh`
- Modo medido: `tfg_axi_memtool rw-loop`
- Validación previa: lectura de `REG_ID` antes de empezar la campaña.
- Carpeta por defecto en la ZedBoard: `/root/t11/raw/`
- Estructura de cada campaña:
  - `campaign_config.txt`
  - `campaign_log.txt`
  - `run_001.csv`, `run_002.csv`, etc.
- Parámetros configurables: identificador de campaña, repeticiones, iteraciones, warm-up, carpeta de salida y ruta alternativa de la herramienta.
- Contexto registrado en cada campaña: bitstream, XSA, DTB, versión Buildroot y FCLK.
- Campañas largas guardadas:
  - `measurements/t11/raw/19700101_001022_t11-rw-1h-60rep/`
  - `measurements/t11/raw/19700101_012744_t11-rw-2h-120rep/`
- Resumen agregado: `measurements/t11/summary/t11_campaign_summary.csv`
- Resultado principal: latencia media alrededor de `335 ns` por iteración `rw-loop` y `0` mismatches en ambas campañas.
- Objetivo de la campaña: obtener varios CSV comparables de una misma configuración para analizar estabilidad y dispersión de la latencia de acceso PS-PL.

## Política de nombres

- Prefijo recomendado de artefactos: `tfg_zedboard`
- Formato de versionado de artefactos: `YYYYMMDD-hhmm`
- Todo artefacto generado deberá incluir fecha/hora o hash de commit.
- Toda evidencia futura deberá referenciar este baseline.
