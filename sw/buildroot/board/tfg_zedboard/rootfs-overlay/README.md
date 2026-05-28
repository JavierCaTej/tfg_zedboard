# Rootfs overlay

Este directorio se copia sobre el root filesystem generado por Buildroot. Su estructura debe reflejar la ruta final que tendrá cada fichero dentro de Linux.

Estructura reservada en esta fase:

- `etc/tfg/`: configuración específica del proyecto.
- `usr/local/bin/`: scripts de usuario para validación y pruebas rápidas.
- `opt/tfg/config/`: ficheros auxiliares del proyecto que no pertenecen a `/etc`.
- `opt/tfg/tests/`: utilidades o scripts de prueba ligados al periférico.
- `opt/tfg/results/`: ubicación prevista para volcar resultados o salidas de prueba.

En `T8` solo se reserva la estructura. En `T10` se añadió la utilidad `tfg_axi_memtool` en `usr/local/bin/` para que la imagen SD generada por Buildroot incluya el binario de validación y medida con `/dev/mem`.

En `T11` se añade también `run_rw_campaign.sh` en `usr/local/bin/`. Este script lanza campañas repetidas de `rw-loop` y guarda los CSV, el log y la configuración de campaña dentro de la propia ZedBoard.

El `PATH` del sistema se ajusta con `etc/profile.d/tfg-path.sh` para que `/usr/local/bin` quede disponible al arrancar sin exportarlo a mano.

Para actualizar el binario del overlay desde las fuentes:

```bash
./sw/linux-tests/install_to_rootfs_overlay.sh
```

Ese mismo script actualiza también `run_rw_campaign.sh` dentro del overlay.
