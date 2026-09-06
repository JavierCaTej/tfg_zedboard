# Campaign F - `F_trace_detail`

## Objetivo

La campaign F no busca sustituir la medida principal, sino estudiar la forma interna de la latencia. Permite observar picos, dispersion y el coste de medir con mas detalle.

Se ejecutaron dos tipos de traza:

- Traza por iteracion individual.
- Traza por bloques (`trace-block`).

## Resultados

`trace_idle`:

| Fichero | Modo | Filas | Media | Min | Max | Std | Mismatches |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `trace_19700101_000455_112.csv` | iter | 1000 | 1413.882 ns | 1362.000 | 2442.000 | 76.697 | 0 |
| `trace_19700101_000458_113.csv` | block | 100 | 338.092 ns | 335.388 | 507.972 | 17.499 | 0 |

`trace_cpu_2core`:

| Fichero | Modo | Filas | Media | Min | Max | Std | Mismatches |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `trace_19700101_000516_118.csv` | block | 100 | 637.043 ns | 335.394 | 10393.650 | 1721.127 | 0 |

## Interpretacion

La traza por iteracion individual presenta una media mucho mayor que la medida agregada normal. Esto no significa que el acceso real sea de `1413 ns`; significa que medir cada iteracion introduce mucho overhead. Cada iteracion llama al reloj, registra el tiempo y genera una traza mucho mas intrusiva.

Por ese motivo, las microtrazas no deben usarse como medida principal de latencia. Su valor esta en mostrar forma, picos y dispersion.

La traza por bloques en reposo queda mucho mas cerca de la latencia normal, aunque aparece algun pico. La traza con CPU 2 cores muestra picos mucho mas altos, con maximo de `10393.650 ns`, lo que visualmente refuerza la idea de que la carga del sistema puede introducir esperas puntuales.

## Graficas recomendadas

- `measurements/t12_analysis/F_trace_detail/trace_idle/plots/trace_01_iter.png`
- `measurements/t12_analysis/F_trace_detail/trace_idle/plots/trace_02_block.png`
- `measurements/t12_analysis/F_trace_detail/trace_cpu_2core/plots/trace_01_block.png`

## Frase util para la memoria

Las microtrazas muestran que aumentar la granularidad de medida introduce overhead y puede alterar la latencia observada. Por ello se utilizan como apoyo visual para estudiar picos y dispersion, mientras que la conclusion principal se obtiene de los CSV resumen por run.
