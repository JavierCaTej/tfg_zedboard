# Analisis T12 con GNU Octave

Estos scripts leen las campaigns guardadas en `measurements/t12/<campaign>/`.
Estan pensados para el arbol que se esta usando ahora:

```text
measurements/t12/A_idle_1h/
  campaign_config.txt
  campaign_log.txt
  system_status.csv
  run_01/
    tfg_axi_memtool_rw_loop_*.csv
    tfg_axi_memtool_rw_loop_trace_*.csv
```

## Que se puede analizar

Con los CSV resumen se puede estudiar:

- evolucion de `avg_ns` por run;
- media, desviacion tipica, minimo y maximo por campaign;
- comparacion entre reposo y carga de CPU;
- comprobacion de `mismatches = 0`;
- duracion total real de cada campaign.

Con los CSV `trace-block` se puede estudiar:

- latencia media de cada bloque dentro de un run;
- picos o dispersion dentro de una repeticion;
- evolucion de todos los bloques a lo largo de la campaign;
- comparacion entre una campaign en reposo y otra con CPU cargada.

La traza por bloques no muestra cada iteracion individual. Muestra grupos de
`trace_block` iteraciones. Por ejemplo, con `180000000` iteraciones y
`trace_block=100000`, cada run tiene `1800` filas de traza.

## Donde se guardan los resultados

No guardo las graficas dentro de `measurements/t12`, porque ahi quiero mantener
los datos originales tal como salieron de la ZedBoard.

Los resultados que genera Octave se guardan en:

```text
measurements/t12_analysis/<campaign>/
  data/
    campaign_summary.csv
    trace_stats_by_run.csv
    trace_run_001.csv
    trace_full_campaign_sampled.csv
  plots/
    01_runs_avg_vs_time.png
    02_hist_run_avg.png
    03_trace_one_run.png
    04_trace_full_campaign.png
    05_trace_stats_by_run.png
    06_representative_runs_summary.png
    07_trace_min_run.png
    07_trace_mean_run.png
    07_trace_max_run.png
```

Para la comparacion entre campaigns:

```text
measurements/t12_analysis/comparison/
  data/
    comparison_summary.csv
    comparison_all_runs.csv
  plots/
    01_comparison_mean_std.png
    02_comparison_all_runs.png
    03_comparison_histograms.png
```

De esta forma queda separado:

- `measurements/t12`: datos en bruto copiados de la ZedBoard.
- `measurements/t12_analysis`: datos procesados y graficas generadas.

## Uso basico

Desde la raiz del repositorio:

```sh
sh measurements/octave/regenerate_t12_analysis.sh
```

Ese script regenera todas las graficas y CSV procesados de T12.

Tambien se puede lanzar una campaign concreta desde Octave:

```octave
addpath('measurements/octave')

t12_plot_campaign('measurements/t12/A_idle_1h')
t12_plot_campaign('measurements/t12/B_idle_5h')
t12_plot_campaign('measurements/t12/C_cpu_1core_1h')
t12_plot_campaign('measurements/t12/C_cpu_2core_1h')
```

Tambien se puede lanzar directamente desde terminal:

```sh
octave --quiet --eval "addpath('measurements/octave'); t12_plot_campaign('measurements/t12/A_idle_1h')"
```

Las graficas se guardan por defecto en:

```text
measurements/t12_analysis/<campaign>/plots/
```

Los CSV procesados se guardan en:

```text
measurements/t12_analysis/<campaign>/data/
```

Para elegir que run se usa en la grafica detallada:

```octave
t12_plot_campaign('measurements/t12/A_idle_1h', '', 30)
```

## Comparar campaigns

```octave
addpath('measurements/octave')

t12_compare_campaigns({
  'measurements/t12/A_idle_1h',
  'measurements/t12/B_idle_5h',
  'measurements/t12/C_cpu_1core_1h',
  'measurements/t12/C_cpu_2core_1h'
})
```

Esto genera:

- `comparison_summary.csv`;
- `comparison_all_runs.csv`;
- grafica de media y desviacion tipica;
- grafica de `avg_ns` por run para todas las campaigns;
- histogramas normalizados para comparar dispersion.

## Graficas mas utiles para la memoria

Las graficas mas defendibles para el TFG son:

- `avg_ns` frente a tiempo acumulado: muestra estabilidad o deriva.
- media con desviacion tipica por campaign: compara reposo frente a carga CPU.
- histograma de `avg_ns`: muestra si una campaign es estable o tiene mucha dispersion.
- trace-block de un run: enseña que ocurre dentro de una repeticion.
- trace-block completo de la campaign: muestra picos y variacion temporal fina.
- trazas del run minimo, del run mas cercano a la media y del run maximo:
  permiten comparar casos representativos sin elegir un run a mano.

Para el texto de la memoria, el resultado principal deberia salir de los CSV
resumen. Las trazas por bloques sirven como apoyo visual para explicar ruido,
picos o cambios durante la campaign.

## Como lo usaria para la memoria

Mi idea seria usar:

- `comparison_summary.csv` para la tabla principal de resultados.
- `01_comparison_mean_std.png` para comparar reposo contra carga de CPU.
- `02_comparison_all_runs.png` para ver estabilidad en el tiempo.
- `03_trace_one_run.png` para explicar que ocurre dentro de un run.
- `04_trace_full_campaign.png` si quiero enseñar picos o variacion fina durante toda la campaign.
- `06_representative_runs_summary.png` y las trazas `07_trace_*` para comparar
  el mejor caso, un caso medio y el peor caso de la misma campaign.

Las graficas de trace-block son de apoyo. La conclusion principal debe salir de
los CSV resumen por run, porque son menos intrusivos y representan mejor la
medida agregada.
