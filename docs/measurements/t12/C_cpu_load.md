# Campaign C - Carga de CPU

## Objetivo

La campaign C estudia si la latencia de acceso al periferico AXI4-Lite cambia cuando el procesador ejecuta carga concurrente. Se han ejecutado dos variantes:

- `C_cpu_1core_1h`: un proceso `yes > /dev/null`.
- `C_cpu_2core_1h`: dos procesos `yes > /dev/null`.

El objetivo no es modificar el hardware, sino estudiar el efecto del sistema operativo y de la planificacion de Linux sobre una medida hecha desde espacio de usuario.

## Resultados comparados

| Campaign | Media `avg_ns` | Std | Min | Max | Duracion | Mismatches |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `A_idle_1h` | 335.264 ns | 0.013 | 335.236 | 335.287 | 1.005792 h | 0 |
| `C_cpu_1core_1h` | 335.231 ns | 0.017 | 335.197 | 335.275 | 1.005694 h | 0 |
| `C_cpu_2core_1h` | 511.386 ns | 11.467 | 485.352 | 539.850 | 1.534159 h | 0 |

Frente a reposo:

- `C_cpu_1core_1h`: -0.033 ns, aproximadamente -0.010 %. No hay impacto relevante.
- `C_cpu_2core_1h`: +176.122 ns, aproximadamente +52.532 %. Impacto muy claro.

## Runs representativos

`C_cpu_1core_1h`:

| Tipo | Run | `avg_ns` |
| --- | ---: | ---: |
| Min | `run_34` | 335.197 ns |
| Mean | `run_31` | 335.231 ns |
| Max | `run_22` | 335.275 ns |

`C_cpu_2core_1h`:

| Tipo | Run | `avg_ns` |
| --- | ---: | ---: |
| Min | `run_29` | 485.352 ns |
| Mean | `run_20` | 511.332 ns |
| Max | `run_21` | 539.850 ns |

## Interpretacion

La carga con un solo proceso no cambia de forma apreciable la latencia respecto a reposo. Esto puede interpretarse como que el sistema todavia tiene capacidad para ejecutar la medida sin que el proceso de carga compita de forma critica con `tfg_axi_memtool`.

La carga con dos procesos cambia completamente el comportamiento. La latencia media sube hasta `511.386 ns`, con una desviacion tipica de `11.467 ns`. Ademas, el analisis por `trace-block` muestra una dispersion mucho mayor que en reposo.

Esta es una de las conclusiones mas importantes del TFG: aunque el periferico AXI4-Lite sea el mismo, la latencia observada desde Linux depende claramente del contexto de ejecucion. En particular, cuando ambos cores estan ocupados, la planificacion del kernel y la competencia por CPU afectan a la medida.

## Graficas recomendadas

- `measurements/t12_analysis/comparison_loads_1h/plots/01_comparison_mean_std.png`
- `measurements/t12_analysis/comparison_loads_1h/plots/02_comparison_all_runs.png`
- `measurements/t12_analysis/C_cpu_2core_1h/plots/04_trace_full_campaign.png`
- `measurements/t12_analysis/C_cpu_2core_1h/plots/07_trace_min_run.png`
- `measurements/t12_analysis/C_cpu_2core_1h/plots/07_trace_mean_run.png`
- `measurements/t12_analysis/C_cpu_2core_1h/plots/07_trace_max_run.png`

## Frase util para la memoria

La carga de CPU con un solo proceso no modifica de forma significativa la latencia, mientras que ocupar ambos cores incrementa la media en torno a un `52.5 %`. Esto confirma que la medida desde espacio de usuario esta condicionada por la planificacion y la carga del sistema operativo.
