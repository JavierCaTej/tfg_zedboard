# Baseline del proyecto

- Fecha de creación: 2026-04-20
- Raíz del proyecto: `tfg_zedboard`
- Estado: `T1.14` completado

## Plataforma

- Placa objetivo: `Digilent ZedBoard`
- SoC: `XC7Z020-CLG484-1`
- Estrategia de arranque: `SD`

## Versiones congeladas

- Vivado: `2022.2`
- Vitis: `2022.2`
- Ubuntu host real: `Ubuntu 20.04.6 LTS`
- Buildroot congelado: `2023.02.9`

## Verificación del host

- `lsb_release -a`
  - `Distributor ID: Ubuntu`
  - `Description: Ubuntu 20.04.6 LTS`
  - `Release: 20.04`
  - `Codename: focal`
- `uname -a`
  - `Linux javier-Aspire-E5-575G 5.15.0-139-generic #149~20.04.1-Ubuntu SMP Wed Apr 16 08:29:56 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux`
- Espacio libre en `/`
  - `Filesystem: /dev/sdb5`
  - `Size: 439G`
  - `Used: 302G`
  - `Avail: 115G`
  - `Use%: 73%`
- Evaluación
  - El host arranca sobre `Ubuntu 20.04 LTS`, alineado con la familia soportada por la guía.
  - Existe una desviación metodológica menor: la guía cita subversiones `20.04.1-20.04.4` y el host real es `20.04.6`.
  - El espacio libre actual (`115G`) es suficiente para continuar con Vivado, Vitis y Buildroot.

## Dependencias mínimas de Buildroot

- Fecha de verificación: `2026-04-21T17:57:58+02:00`
- Comprobación realizada con `dpkg -s`
- Paquetes mínimos verificados como instalados
  - `make`
  - `gcc`
  - `g++`
  - `bash`
  - `sed`
  - `patch`
  - `gzip`
  - `bzip2`
  - `perl`
  - `tar`
  - `wget`
  - `libncurses-dev`
- Evaluación
  - Se cumple `T1.14`: las dependencias mínimas para Buildroot ya están presentes en el host.

## Nombres congelados

- Nombre del proyecto Vivado: `tfg_zedboard`
- Nombre del IP AXI-Lite: `tfg_axi_lite_regs`

## Política de nombres

- Prefijo recomendado de artefactos: `tfg_zedboard`
- Formato de versionado de artefactos: `YYYYMMDD-hhmm`
- Todo artefacto generado deberá incluir fecha/hora o hash de commit.
- Toda evidencia futura deberá referenciar este baseline.
