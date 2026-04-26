# Baseline del proyecto

- Fecha de creación: 2026-04-20
- Raíz del proyecto: `tfg_zedboard`
- Estado: `T8` completada

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

## Estado de Buildroot

- `T7` cerrada a nivel de build base reproducible.
- Versión usada: `Buildroot 2023.02.9`
- Árbol fuente: `sw/buildroot/buildroot-2023.02.9/`
- Defconfig propia del proyecto: `sw/buildroot/configs/tfg_zedboard_defconfig`
- Directorio de salida out-of-tree: `sw/buildroot/output/zedboard/`
- Script de invocación: `sw/buildroot/scripts/build_buildroot.sh`
- Artefactos principales congelados en `artifacts/buildroot/`
- U-Boot ELF para volver a `T6`: `artifacts/buildroot/u-boot.elf`
- Kernel generado: `artifacts/buildroot/uImage`
- DTB actual: `artifacts/buildroot/system.dtb`
- Root filesystem base: `artifacts/buildroot/rootfs.ext4`
- Imagen SD base generada por Buildroot: `artifacts/buildroot/sdcard.img`
- Nota: el `BOOT.bin` final del proyecto no queda cerrado en `T7`; se generará al volver a `T6` con el `FSBL`, el bitstream y el U-Boot ELF trazado.

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

## Política de nombres

- Prefijo recomendado de artefactos: `tfg_zedboard`
- Formato de versionado de artefactos: `YYYYMMDD-hhmm`
- Todo artefacto generado deberá incluir fecha/hora o hash de commit.
- Toda evidencia futura deberá referenciar este baseline.
