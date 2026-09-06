# Campaign A - `A_idle_1h`

## Objetivo

Esta campaign establece la referencia base del sistema en reposo. Es la medida principal contra la que se comparan el resto de condiciones: carga de CPU, carga de I/O y campaigns de escala.

La idea es medir el acceso normal al periferico AXI4-Lite desde Linux sin introducir carga adicional en el sistema.

## Configuracion

| Parametro | Valor |
| --- | --- |
| Condicion | Reposo |
| Repeticiones | 60 |
| Iteraciones por run | 180000000 |
| Warmup | 1000000 |
| Trace block | 100000 |
| Duracion real | 1.005792 h |

Datos:

```text
measurements/t12/A_idle_1h/
measurements/t12_analysis/A_idle_1h/
```

## Resultados

| Metrica | Valor |
| --- | ---: |
| Media `avg_ns` | 335.264 ns |
| Desviacion tipica | 0.013 ns |
| Minimo | 335.236 ns |
| Maximo | 335.287 ns |
| Mismatches | 0 |

Runs representativos:

| Tipo | Run | `avg_ns` |
| --- | ---: | ---: |
| Min | `run_14` | 335.236 ns |
| Mean | `run_18` | 335.264 ns |
| Max | `run_28` | 335.287 ns |

## Interpretacion

La campaign muestra una latencia extremadamente estable alrededor de `335.26 ns`. La diferencia entre el run minimo y el maximo es solo de `0.051 ns`, lo que indica que, en reposo, el acceso medido por `rw-loop` es muy repetible.

El resultado mas importante es que `mismatches = 0`. Esto significa que durante todos los accesos medidos el valor escrito en `WDATA` fue recuperado correctamente desde `RDATA`. Por tanto, la prueba valida tanto el funcionamiento del periferico como la estabilidad de la ruta de acceso desde Linux.

## Graficas recomendadas

- `measurements/t12_analysis/A_idle_1h/plots/01_runs_avg_vs_time.png`
- `measurements/t12_analysis/A_idle_1h/plots/02_hist_run_avg.png`
- `measurements/t12_analysis/A_idle_1h/plots/06_representative_runs_summary.png`
- `measurements/t12_analysis/A_idle_1h/plots/07_trace_mean_run.png`

## Frase util para la memoria

En condiciones de reposo, el acceso `rw-loop` al periferico AXI4-Lite presenta una latencia media de aproximadamente `335 ns` por iteracion, con una dispersion muy baja y sin errores funcionales detectados.
