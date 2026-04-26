# Rootfs overlay

Este directorio se copia sobre el root filesystem generado por Buildroot. Su estructura debe reflejar la ruta final que tendrá cada fichero dentro de Linux.

Estructura reservada en esta fase:

- `etc/tfg/`: configuración específica del proyecto.
- `usr/local/bin/`: scripts de usuario para validación y pruebas rápidas.
- `opt/tfg/config/`: ficheros auxiliares del proyecto que no pertenecen a `/etc`.
- `opt/tfg/tests/`: utilidades o scripts de prueba ligados al periférico.
- `opt/tfg/results/`: ubicación prevista para volcar resultados o salidas de prueba.

En `T8` solo se reserva la estructura. Los contenidos concretos se añadirán cuando se definan las utilidades de acceso al periférico y el flujo de validación desde Linux.
