# tfg_zedboard

Repositorio de trabajo para la parte practica del TFG sobre comunicacion PS-PL en ZedBoard mediante un periferico personalizado `AXI4-Lite`.

El objetivo del proyecto es construir un flujo reproducible desde el diseño hardware en Vivado hasta la validacion posterior desde Linux. El caso de estudio se centra en un periferico de registros accesible desde el PS a traves de `M_AXI_GP0`, usando una ventana AXI4-Lite sencilla para comprobar funcionalidad, trazabilidad y futuras medidas de latencia.

## Estado actual

El repositorio esta cerrado hasta `T8`:

- `T0-T1`: baseline del proyecto y entorno host documentados.
- `T2`: contrato HW/SW del periferico definido.
- `T3`: RTL del IP implementado y simulado.
- `T4`: Block Design base integrado en Vivado.
- `T5`: bitstream generado y hardware exportado a `.xsa`.
- `T6`: iniciada para generar el `FSBL`; el `BOOT.bin` final queda pendiente hasta empaquetar `fsbl.elf`, bitstream y `u-boot.elf`.
- `T7`: Buildroot base construido y artefactos Linux congelados.
- `T8`: device tree adaptado al periférico AXI-Lite y `rootfs-overlay` del proyecto preparado.

La baseline viva del proyecto esta en `docs/baseline.md`.

## Plataforma y versiones

- Placa: `Digilent ZedBoard`
- SoC: `XC7Z020-CLG484-1`
- Vivado: `2022.2`
- Vitis: `2022.2`
- Buildroot fijado: `2023.02.9`
- Reloj PL usado en el Block Design: `FCLK_CLK0 = 100 MHz`
- Direccion base del IP: `0x40000000`
- Rango asignado al IP: `0x1000`

## Estructura del repositorio

- `docs/`: documentacion de trabajo, baseline, matriz de evidencias, capturas y resumen de tareas.
- `docs/tasks/`: resumen breve de cada tarea `T0`, `T1`, `T2`, etc.
- `hw/ip/`: IP personalizado empaquetado para Vivado.
- `hw/ip/tfg_axi_lite_regs_1_0/`: fuentes HDL, especificacion y testbench del periferico `tfg_axi_lite_regs`.
- `hw/vivado/`: proyecto Vivado y scripts de reconstruccion/exportacion.
- `sw/include/`: cabeceras compartidas entre hardware y software, especialmente offsets y mascaras del IP.
- `sw/linux-tests/`: ubicacion prevista para utilidades de validacion desde Linux.
- `sw/vitis/`: ubicacion prevista para workspace o artefactos relacionados con Vitis.
- `sw/buildroot/`: Buildroot, defconfig propia, scripts de build y salida out-of-tree.
- `artifacts/`: artefactos generados y congelados como salidas de etapa.
- `logs/`: logs de ejecucion, especialmente UART durante arranque.
- `measurements/`: resultados futuros de pruebas y campanas de medida.

## Artefactos principales

- Especificacion del IP: `hw/ip/tfg_axi_lite_regs_1_0/spec.md`
- Header software del IP: `sw/include/tfg_axi_lite_regs.h`
- Proyecto Vivado: `hw/vivado/tfg_zedboard/tfg_zedboard.xpr`
- Script Tcl del Block Design: `hw/vivado/scripts/tfg_zedboard_bd.tcl`
- Script Tcl del proyecto Vivado: `hw/vivado/scripts/tfg_zedboard_project.tcl`
- Bitstream final: `artifacts/hw/tfg_zedboard_bd_wrapper.bit`
- Exportacion hardware para Vitis: `artifacts/hw/tfg_zedboard.xsa`
- Artefactos Buildroot: `artifacts/buildroot/`
- U-Boot ELF para `BOOT.bin`: `artifacts/buildroot/u-boot.elf`
- Kernel Linux: `artifacts/buildroot/uImage`
- Device tree actual: `artifacts/buildroot/system.dtb`
- Root filesystem base: `artifacts/buildroot/rootfs.ext4`
- Imagen SD base: `artifacts/buildroot/sdcard.img`
- Matriz de evidencias: `docs/evidence-matrix.md`

## Flujo general

El flujo previsto del proyecto es:

```text
Especificacion del IP
-> RTL + simulacion
-> Block Design en Vivado
-> bitstream + XSA
-> Buildroot
-> FSBL / BOOT.bin con Vitis
-> arranque en ZedBoard
-> validacion desde Linux
-> captura de resultados
```

Hasta el estado actual, el trabajo llega hasta la adaptación del device tree y la preparación del rootfs base. El siguiente paso tecnico natural es volver a `T6` para empaquetar el `BOOT.bin` final con `fsbl.elf`, el bitstream de Vivado y `u-boot.elf`.

## Regeneracion de artefactos hardware

Despues de generar una nueva implementacion en Vivado, se puede sincronizar el bitstream y los informes `.rpt` principales con:

```bash
./hw/vivado/scripts/sync_hw_artifacts.sh
```

El script copia el `.bit` a `artifacts/hw/` y los informes `.rpt` a `artifacts/hw/reports/`.

## Criterio de organizacion

Las fuentes y documentos editables se encuentran en `hw/`, `sw/` y `docs/`. Los ficheros generados que se quieren conservar como salida cerrada de una etapa se encuentran en `artifacts/`. Los directorios temporales o generados por Vivado se ignoran mediante `.gitignore` para evitar la sobrecarga del repositorio.
