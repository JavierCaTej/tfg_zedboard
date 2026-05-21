# Utilidades Linux de validacion

Esta carpeta contiene las utilidades de usuario usadas para validar y medir el periférico AXI4-Lite desde Linux.

## `tfg_axi_memtool`

`tfg_axi_memtool` accede al periférico mediante `/dev/mem`, mapea la ventana física `0x40000000` y permite hacer una prueba funcional básica y bucles de medida sin depender de scripts de shell en el camino crítico.

Compilación para la ZedBoard usando el toolchain generado por Buildroot:

```bash
make -C sw/linux-tests
```

Instalación en el `rootfs-overlay` para que aparezca automáticamente en futuras imágenes SD:

```bash
./sw/linux-tests/install_to_rootfs_overlay.sh
./sw/buildroot/scripts/build_buildroot.sh
./sw/buildroot/scripts/sync_buildroot_artifacts.sh
```

El binario queda instalado en la imagen final como:

```text
/usr/local/bin/tfg_axi_memtool
```

El flujo detallado para actualizar el binario dentro de Buildroot está documentado en:

```text
sw/linux-tests/tfg_axi_memtool_buildroot.md
```

Uso básico en la placa:

```bash
tfg_axi_memtool smoke
tfg_axi_memtool read 0x00
tfg_axi_memtool write 0x10 0x12345678
tfg_axi_memtool rw-loop --iters 100000 --warmup 1000 --csv --build-id t10-prueba
tfg_axi_memtool rw-loop --iters 100000 --warmup 1000 --build-id t10-prueba -C /root/t10
```

Opciones principales:

- `--base 0x40000000`: dirección base física del periférico.
- `--size 0x1000`: tamaño de la ventana mapeada.
- `--dev /dev/mem`: dispositivo de memoria física.
- `--iters N`: iteraciones medidas.
- `--warmup N`: iteraciones previas no medidas.
- `--csv`: salida en CSV para campañas de medida.
- `--build-id TEXTO`: identificador de la build o prueba.
- `-C RUTA` o `--csv-dir RUTA`: carpeta donde `rw-loop` guarda automaticamente un CSV.

El modo `rw-loop` guarda siempre un fichero CSV con nombre distinto. Si no se indica `-C`, el fichero se guarda en el directorio desde el que se ejecuta el comando. El nombre incluye fecha, hora y PID del proceso para evitar sobrescribir medidas anteriores.

El programa comprueba por defecto que `REG_ID` vale `0x54464700` antes de operar. Si esa comprobación falla, lo más probable es que la PL no esté cargada, que el `dtb` no describa el mismo rango o que la dirección base no coincida con la asignada en Vivado.
