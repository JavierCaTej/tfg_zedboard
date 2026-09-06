# Campaign D - `D_sd_io_1h`

## Objetivo

Esta campaign introduce carga de escritura sobre la SD mientras se mide el acceso `rw-loop` al periferico AXI4-Lite.

Es importante aclarar que la carga de SD no estresa directamente el bus AXI4-Lite del periferico. La prueba busca observar si una actividad de sistema no relacionada con la PL puede introducir ruido en la medida hecha desde Linux.

## Configuracion

| Parametro | Valor |
| --- | --- |
| Condicion | Escritura repetida en SD con `dd` |
| Repeticiones | 60 |
| Iteraciones por run | 180000000 |
| Warmup | 1000000 |
| Trace block | 100000 |
| Duracion real | 1.022861 h |

Datos:

```text
measurements/t12/D_sd_io_1h/
measurements/t12_analysis/D_sd_io_1h/
```

## Resultados

| Metrica | Valor |
| --- | ---: |
| Media `avg_ns` | 340.954 ns |
| Desviacion tipica | 0.297 ns |
| Minimo | 340.701 ns |
| Maximo | 341.990 ns |
| Mismatches | 0 |

Frente a `A_idle_1h`:

```text
Incremento medio = 5.690 ns
Incremento relativo = 1.697 %
```

Runs representativos:

| Tipo | Run | `avg_ns` |
| --- | ---: | ---: |
| Min | `run_36` | 340.701 ns |
| Mean | `run_55` | 340.944 ns |
| Max | `run_20` | 341.990 ns |

## Interpretacion

La carga de I/O sobre la SD incrementa la latencia media respecto a reposo, pero el efecto es moderado comparado con la carga de CPU a dos cores.

Este resultado es util para la memoria porque ayuda a delimitar el alcance experimental: el periferico AXI4-Lite no cambia, pero el entorno Linux si puede introducir variaciones en la medida. La actividad de SD probablemente afecta por actividad del kernel, interrupciones, escritura en almacenamiento y planificacion de procesos.

No se puede afirmar que cada pico de la traza coincida exactamente con una escritura concreta de `dd`, porque el CSV de `trace-block` no sincroniza eventos de I/O con bloques de medida. Lo correcto es presentar la prueba como una condicion de ruido del sistema, no como una caracterizacion directa del AXI4-Lite.

## Graficas recomendadas

- `measurements/t12_analysis/D_sd_io_1h/plots/01_runs_avg_vs_time.png`
- `measurements/t12_analysis/D_sd_io_1h/plots/04_trace_full_campaign.png`
- `measurements/t12_analysis/D_sd_io_1h/plots/06_representative_runs_summary.png`
- `measurements/t12_analysis/D_sd_io_1h/plots/07_trace_mean_run.png`
- `measurements/t12_analysis/comparison_loads_1h/plots/01_comparison_mean_std.png`

## Frase util para la memoria

La carga de I/O sobre la SD aumenta la latencia media en torno a un `1.7 %`, lo que indica que la medida desde Linux es sensible a actividad del sistema, aunque el efecto es mucho menor que el observado con los dos cores de CPU ocupados.
