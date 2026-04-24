# Baseline del proyecto

- Fecha de creación: 2026-04-20
- Raíz del proyecto: `tfg_zedboard`
- Estado: `T5` completada

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

## Política de nombres

- Prefijo recomendado de artefactos: `tfg_zedboard`
- Formato de versionado de artefactos: `YYYYMMDD-hhmm`
- Todo artefacto generado deberá incluir fecha/hora o hash de commit.
- Toda evidencia futura deberá referenciar este baseline.
