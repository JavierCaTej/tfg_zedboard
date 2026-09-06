# Campaign B - `B_idle_5h`

## Objetivo

Esta campaign comprueba si el comportamiento observado en reposo se mantiene durante una ejecucion larga. No busca cambiar la carga del sistema, sino confirmar estabilidad temporal.

Es importante para el TFG porque permite defender que la SD estable, el bitstream y el sistema Linux pueden ejecutar medidas largas sin degradacion funcional.

## Configuracion

| Parametro | Valor |
| --- | --- |
| Condicion | Reposo largo |
| Repeticiones | 300 |
| Iteraciones por run | 180000000 |
| Warmup | 1000000 |
| Trace block | 100000 |
| Duracion real | 5.029217 h |

Datos:

```text
measurements/t12/B_idle_5h/
measurements/t12_analysis/B_idle_5h/
```

## Resultados

| Metrica | Valor |
| --- | ---: |
| Media `avg_ns` | 335.281 ns |
| Desviacion tipica | 0.014 ns |
| Minimo | 335.235 ns |
| Maximo | 335.321 ns |
| Mismatches | 0 |

Runs representativos:

| Tipo | Run | `avg_ns` |
| --- | ---: | ---: |
| Min | `run_101` | 335.235 ns |
| Mean | `run_018` | 335.281 ns |
| Max | `run_116` | 335.321 ns |

## Interpretacion

La media de `B_idle_5h` es practicamente igual a la de `A_idle_1h`. La diferencia entre ambas es de `0.017 ns`, que es despreciable para la escala de esta medida.

Esto permite concluir que el sistema se mantiene estable durante al menos 5 horas de ejecucion continua. No aparecen mismatches, por lo que tampoco se observa degradacion funcional en el periferico ni en el acceso desde Linux.

La campaign B es una evidencia fuerte de estabilidad, pero para la memoria puede presentarse como confirmacion de la referencia A, no necesariamente como la grafica principal.

## Graficas recomendadas

- `measurements/t12_analysis/B_idle_5h/plots/01_runs_avg_vs_time.png`
- `measurements/t12_analysis/B_idle_5h/plots/04_trace_full_campaign.png`
- `measurements/t12_analysis/B_idle_5h/plots/06_representative_runs_summary.png`

## Frase util para la memoria

La campaign de reposo de 5 horas mantiene una latencia media practicamente identica a la campaign de 1 hora y no registra ningun mismatch, por lo que refuerza la estabilidad temporal del sistema experimental.
