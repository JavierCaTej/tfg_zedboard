# tfg_zedboard

Repositorio de trabajo para la parte practica del TFG sobre comunicacion PS-PL en ZedBoard mediante un periferico personalizado `AXI4-Lite`.

El objetivo del proyecto es construir un flujo reproducible desde el diseño hardware en Vivado hasta la validacion posterior desde Linux. El caso de estudio se centra en un periferico de registros accesible desde el PS a traves de `M_AXI_GP0`, usando una ventana AXI4-Lite sencilla para comprobar funcionalidad, trazabilidad y futuras medidas de latencia.

## Estado actual

El repositorio esta cerrado hasta `T11`:

- `T0-T1`: baseline del proyecto y entorno host documentados.
- `T2`: contrato HW/SW del periferico definido.
- `T3`: RTL del IP implementado y simulado.
- `T4`: Block Design base integrado en Vivado.
- `T5`: bitstream generado y hardware exportado a `.xsa`.
- `T6`: `FSBL` y `BOOT.bin` generados como artefactos; el arranque activo vuelve a usar `U-Boot SPL`.
- `T7`: Buildroot base construido y artefactos Linux congelados.
- `T8`: device tree adaptado al periférico AXI-Lite y `rootfs-overlay` preparado.
- `T9`: SD estable asegurada con `U-Boot SPL`, carga automática del bitstream y validación en placa.
- `T10`: utilidad de usuario con `/dev/mem` implementada, integrada en `rootfs-overlay` y validada como parte del flujo de trabajo.
- `T11`: campañas `rw-loop` automatizadas, con CSV, configuración, log y resumen agregado de campañas de 1h y 2h.

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
- `sw/linux-tests/`: utilidades de validacion y medida desde Linux, incluyendo `tfg_axi_memtool`.
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
- FSBL final: `artifacts/boot/fsbl.elf`
- BOOT.bin FSBL de diagnóstico: `artifacts/boot/BOOT.bin`
- Artefactos Buildroot: `artifacts/buildroot/`
- Primer cargador SPL activo: `artifacts/buildroot/boot-spl.bin`
- U-Boot activo: `artifacts/buildroot/u-boot.img`
- U-Boot ELF auxiliar: `artifacts/buildroot/u-boot.elf`
- Bitstream incluido para U-Boot: `artifacts/buildroot/tfg_zedboard_bd_wrapper.bit`
- Kernel Linux: `artifacts/buildroot/uImage`
- Device tree actual: `artifacts/buildroot/system.dtb`
- Root filesystem base: `artifacts/buildroot/rootfs.ext4`
- Imagen SD estable: `artifacts/buildroot/sdcard.img`
- Documento del flujo SD estable: `docs/boot/sd-estable-buildroot-uboot.md`
- Utilidad Linux de acceso al IP: `sw/linux-tests/tfg_axi_memtool.c`
- Script de campañas de medida: `measurements/t11/run_rw_campaign.sh`
- Resumen de campañas T11: `measurements/t11/summary/t11_campaign_summary.csv`
- Perfil del sistema para incluir `/usr/local/bin` en `PATH`: `sw/buildroot/board/tfg_zedboard/rootfs-overlay/etc/profile.d/tfg-path.sh`
- Matriz de evidencias: `docs/evidence-matrix.md`

## Flujo general

El flujo previsto del proyecto es:

```text
Especificacion del IP
-> RTL + simulacion
-> Block Design en Vivado
-> bitstream + XSA
-> Buildroot
-> arranque estable con U-Boot SPL
-> carga automatica del bitstream desde U-Boot
-> validacion desde Linux
-> captura de resultados
```

Hasta el estado actual, el arranque estable usa `U-Boot SPL`. La imagen SD incluye el bitstream en la particion `boot` y U-Boot queda compilado con un `bootcmd` propio que carga automaticamente la PL antes de arrancar Linux. La validacion en placa confirma `devmem 0x40000000 -> 0x54464700`.

La siguiente validacion se realiza con `sw/linux-tests/tfg_axi_memtool`, una utilidad C que accede al rango AXI-Lite mediante `/dev/mem`, verifica `REG_ID` y ejecuta pruebas funcionales y bucles de medida.

Para repetir medidas de forma ordenada se usa `run_rw_campaign.sh`, que lanza varias ejecuciones de `rw-loop`, guarda cada CSV como `run_001.csv`, `run_002.csv`, etc. y deja junto a ellos un `campaign_config.txt` con los parámetros de la campaña.
El `PATH` del sistema ya incluye `/usr/local/bin` al arrancar, así que en la ZedBoard se pueden lanzar directamente `tfg_axi_memtool` y `run_rw_campaign.sh` sin exportar nada a mano.
Las primeras campañas largas guardadas en `measurements/t11/raw/` confirman `0` mismatches y una latencia media cercana a `335 ns` por iteración `rw-loop`.

## Regeneracion de artefactos hardware

Despues de generar una nueva implementacion en Vivado, se puede sincronizar el bitstream y los informes `.rpt` principales con:

```bash
./hw/vivado/scripts/sync_hw_artifacts.sh
```

El script copia el `.bit` a `artifacts/hw/` y los informes `.rpt` a `artifacts/hw/reports/`.

## Regeneracion de artefactos de arranque

Los artefactos de `T6` se conservan como diagnostico del flujo `FSBL + BOOT.bin`:

```bash
./sw/vitis/scripts/run_create_fsbl.sh
./sw/vitis/scripts/generate_boot_bin.sh
```

El flujo activo de la SD no usa ese `BOOT.bin`; usa el `boot.bin` SPL generado por Buildroot.

Para reconstruir la SD estable uso:

```bash
./sw/buildroot/scripts/build_buildroot.sh project-defconfig
./sw/buildroot/scripts/build_buildroot.sh uboot-reconfigure
./sw/buildroot/scripts/build_buildroot.sh
./sw/buildroot/scripts/sync_buildroot_artifacts.sh
```

El resultado final a grabar es `artifacts/buildroot/sdcard.img`.

## Criterio de organizacion

Las fuentes y documentos editables se encuentran en `hw/`, `sw/` y `docs/`. Los ficheros generados que se quieren conservar como salida cerrada de una etapa se encuentran en `artifacts/`. Los directorios temporales o generados por Vivado se ignoran mediante `.gitignore` para evitar la sobrecarga del repositorio.
