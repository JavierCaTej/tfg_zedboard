# Comparaciones recomendadas para la memoria

Este documento recoge que comparaciones tienen mas sentido para el TFG. La idea es evitar presentar demasiadas graficas sin foco y centrar el analisis en lo que realmente demuestra el comportamiento del sistema.

## Comparacion principal: reposo frente a carga

Ficheros:

```text
measurements/t12_analysis/comparison_loads_1h/data/comparison_summary.csv
measurements/t12_analysis/comparison_loads_1h/plots/01_comparison_mean_std.png
measurements/t12_analysis/comparison_loads_1h/plots/02_comparison_all_runs.png
measurements/t12_analysis/comparison_loads_1h/plots/03_comparison_histograms.png
```

Tabla:

| Campaign | Media `avg_ns` | Std | Mismatches | Interpretacion |
| --- | ---: | ---: | ---: | --- |
| `A_idle_1h` | 335.264 | 0.013 | 0 | Referencia base |
| `C_cpu_1core_1h` | 335.231 | 0.017 | 0 | Equivalente a reposo |
| `C_cpu_2core_1h` | 511.386 | 11.467 | 0 | Impacto fuerte de CPU |
| `D_sd_io_1h` | 340.954 | 0.297 | 0 | Impacto moderado de I/O |

Conclusiones:

- La latencia base se situa alrededor de `335 ns`.
- La carga de 1 core no modifica de forma relevante la medida.
- La carga de 2 cores aumenta la latencia un `52.5 %`.
- La carga de I/O sobre SD aumenta la latencia un `1.7 %`.
- No hay errores funcionales en ninguna condicion.

Esta es la comparacion mas importante para el documento del TFG.

## Comparacion de estabilidad: A frente a B

Ficheros:

```text
measurements/t12_analysis/A_idle_1h/data/campaign_summary.csv
measurements/t12_analysis/B_idle_5h/data/campaign_summary.csv
```

Tabla:

| Campaign | Duracion | Media `avg_ns` | Std | Mismatches |
| --- | ---: | ---: | ---: | ---: |
| `A_idle_1h` | 1.005792 h | 335.264 | 0.013 | 0 |
| `B_idle_5h` | 5.029217 h | 335.281 | 0.014 | 0 |

Conclusion:

La diferencia entre 1 hora y 5 horas es despreciable. Esta comparacion sirve para demostrar estabilidad temporal, no para introducir una nueva condicion de carga.

## Comparacion de escala de iteraciones

Ficheros:

```text
measurements/t12_analysis/comparison_E_scale/data/comparison_summary.csv
measurements/t12_analysis/comparison_E_scale/plots/01_comparison_mean_std.png
```

Tabla:

| Campaign | Iteraciones | Media `avg_ns` | Std |
| --- | ---: | ---: | ---: |
| `E_scale_iters_001_1M` | 1M | 335.650 | 0.186 |
| `E_scale_iters_002_10M` | 10M | 335.276 | 0.060 |
| `E_scale_iters_003_100M` | 100M | 335.259 | 0.020 |
| `E_scale_iters_004_180M` | 180M | 335.260 | 0.015 |

Conclusion:

La media converge con el numero de iteraciones y la desviacion baja. Esta comparacion justifica la metodologia de usar runs largos.

## Comparacion de trazas representativas

Cada campaign principal tiene:

```text
plots/06_representative_runs_summary.png
plots/07_trace_min_run.png
plots/07_trace_mean_run.png
plots/07_trace_max_run.png
```

Estas graficas sirven para no depender de `run_001`. El run `mean` no es la media matematica, sino el run real cuyo `avg_ns` queda mas cerca de la media de la campaign.

Uso recomendado:

- En reposo, mostrar que min/mean/max son casi indistinguibles.
- En CPU 2 cores, mostrar que min/mean/max son muy distintos.
- En I/O SD, mostrar que hay subida moderada y algo mas de dispersion que en reposo.

## Graficas que usaria en el TFG

Prioridad alta:

- `comparison_loads_1h/plots/01_comparison_mean_std.png`
- `comparison_loads_1h/plots/02_comparison_all_runs.png`
- `comparison_E_scale/plots/01_comparison_mean_std.png`
- `C_cpu_2core_1h/plots/04_trace_full_campaign.png`
- `D_sd_io_1h/plots/04_trace_full_campaign.png`

Prioridad media:

- `A_idle_1h/plots/01_runs_avg_vs_time.png`
- `B_idle_5h/plots/01_runs_avg_vs_time.png`
- `F_trace_detail/trace_cpu_2core/plots/trace_01_block.png`

Prioridad baja:

- Histogramas individuales, salvo que se quiera reforzar la dispersion.
- `run_001`, porque ahora se dispone de min/mean/max.
