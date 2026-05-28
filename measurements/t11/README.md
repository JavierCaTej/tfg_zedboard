# T11. Campañas de medida

Esta carpeta contiene la automatización de campañas para `rw-loop`. El objetivo es dejar de lanzar medidas a mano y tener una forma repetible de generar varios CSV de una misma campaña.

## Script principal

```bash
./measurements/t11/run_rw_campaign.sh \
  --id t11-rw-100M-warmup-1M-5rep \
  --reps 5 \
  --iters 100000000 \
  --warmup 1000000
```

En la ZedBoard el script queda instalado como:

```bash
run_rw_campaign.sh
```

## Salida generada

Por defecto, en la ZedBoard se guarda bajo:

```text
/root/t11/raw/
```

Cada campaña crea una carpeta nueva con fecha y `build_id`:

```text
/root/t11/raw/20260521_183000_t11-rw-100M-warmup-1M-5rep/
```

Dentro quedan:

- `campaign_config.txt`: configuración usada para lanzar la campaña y contexto básico de la imagen usada.
- `campaign_log.txt`: log básico del script.
- `run_001.csv`, `run_002.csv`, etc.: resultados de cada repetición.

## Opciones

- `--id ID`: nombre de la campaña.
- `--reps N`: número de repeticiones.
- `--iters N`: iteraciones medidas por repetición.
- `--warmup N`: iteraciones previas no medidas.
- `--out DIR`: carpeta raíz alternativa para resultados.
- `--tool PATH`: ruta alternativa de `tfg_axi_memtool`.

Antes de lanzar la campaña se hace una validación mínima leyendo `REG_ID`. Si no responde el valor esperado, el script aborta para evitar perder tiempo midiendo una configuración incorrecta.

## Campañas guardadas

En esta tarea quedan guardadas dos campañas largas ejecutadas en la ZedBoard:

- `raw/19700101_001022_t11-rw-1h-60rep/`: campaña de 60 repeticiones, aproximadamente 1 hora.
- `raw/19700101_012744_t11-rw-2h-120rep/`: campaña de 120 repeticiones, aproximadamente 2 horas.

Cada repetición usa `180000000` iteraciones medidas y `1000000` iteraciones de warm-up. Las fechas aparecen como `19700101` porque la ZedBoard no tenía hora real configurada al arrancar; para esta fase no afecta a la validez de la medida porque la trazabilidad queda en el nombre de campaña y en `campaign_config.txt`.

## Resumen de resultados

El resumen agregado está en:

```text
summary/t11_campaign_summary.csv
```

Resultado principal:

| Campaña | Repeticiones | Media `avg_ns` | Desv. típica | Mínimo | Máximo | Mismatches |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `t11-rw-1h-60rep` | 60 | 335.179650 ns | 0.024080 ns | 335.144000 ns | 335.259000 ns | 0 |
| `t11-rw-2h-120rep` | 120 | 335.166267 ns | 0.042394 ns | 335.058000 ns | 335.287000 ns | 0 |

La lectura principal para el TFG es que la campaña larga no muestra errores funcionales (`mismatches = 0`) y que el tiempo medio por operación `rw-loop` se mantiene muy estable alrededor de `335 ns`.
