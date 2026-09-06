# T12 - Analisis experimental de acceso AXI4-Lite desde Linux

Este directorio resume las pruebas experimentales realizadas sobre la ZedBoard para documentar la parte practica del TFG. El objetivo es dejar preparados los resultados para redactar despues el documento final: que se ha medido, por que se ha medido, que muestran las graficas y que conclusiones se pueden defender.

## Objetivo de T12

El objetivo de estas pruebas es caracterizar el acceso desde Linux de usuario a un periferico AXI4-Lite implementado en la PL. La medida principal es el modo `rw-loop` de `tfg_axi_memtool`, que en cada iteracion escribe un valor en el registro `WDATA`, lee el registro `RDATA` y comprueba que ambos coinciden.

Esta operacion es adecuada para el TFG porque no mide solo una lectura aislada, sino un ciclo completo de acceso software-periferico con comprobacion funcional. Por eso las conclusiones se apoyan principalmente en:

- `avg_ns`: latencia media por iteracion.
- `elapsed_ns`: tiempo total del run.
- `mismatches`: errores funcionales detectados.
- `trace-block`: latencia media de bloques internos dentro de cada run.

## Estructura de datos

Los datos brutos copiados de la ZedBoard estan en:

```text
measurements/t12/
```

Los datos procesados y graficas generadas con GNU Octave estan en:

```text
measurements/t12_analysis/
```

El codigo de analisis esta en:

```text
measurements/octave/
```

Para regenerar todo el analisis:

```sh
sh measurements/octave/regenerate_t12_analysis.sh
```

## Campaigns ejecutadas

| Campaign | Condicion | Reps | Iteraciones por run | Objetivo |
| --- | --- | ---: | ---: | --- |
| `A_idle_1h` | Reposo | 60 | 180M | Referencia base de 1 hora |
| `B_idle_5h` | Reposo largo | 300 | 180M | Estabilidad durante 5 horas |
| `C_cpu_1core_1h` | 1 proceso CPU | 60 | 180M | Ver impacto de carga parcial de CPU |
| `C_cpu_2core_1h` | 2 procesos CPU | 60 | 180M | Estresar ambos cores y medir impacto |
| `D_sd_io_1h` | Escritura en SD | 60 | 180M | Evaluar ruido por I/O de almacenamiento |
| `E_scale_iters_*` | Reposo, distintos tamaños | 20 | 1M, 10M, 100M, 180M | Justificar numero de iteraciones |
| `F_trace_detail` | Microtrazas | casos cortos | variable | Ver dispersion fina y coste de instrumentacion |

## Resultados principales

| Campaign | Runs | Media `avg_ns` | Std `avg_ns` | Min | Max | Duracion real | Mismatches |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `A_idle_1h` | 60 | 335.264 ns | 0.013 ns | 335.236 | 335.287 | 1.005792 h | 0 |
| `B_idle_5h` | 300 | 335.281 ns | 0.014 ns | 335.235 | 335.321 | 5.029217 h | 0 |
| `C_cpu_1core_1h` | 60 | 335.231 ns | 0.017 ns | 335.197 | 335.275 | 1.005694 h | 0 |
| `C_cpu_2core_1h` | 60 | 511.386 ns | 11.467 ns | 485.352 | 539.850 | 1.534159 h | 0 |
| `D_sd_io_1h` | 60 | 340.954 ns | 0.297 ns | 340.701 | 341.990 | 1.022861 h | 0 |

Frente a `A_idle_1h`:

- `C_cpu_1core_1h` cambia -0.033 ns, aproximadamente -0.010 %. En la practica es equivalente a reposo.
- `C_cpu_2core_1h` sube 176.122 ns, aproximadamente +52.532 %. Es el efecto mas claro.
- `D_sd_io_1h` sube 5.690 ns, aproximadamente +1.697 %. La SD introduce ruido moderado.

## Conclusiones globales

La latencia base del acceso `rw-loop` en reposo queda alrededor de `335.26 ns` por iteracion. La campaign larga de 5 horas confirma que esta latencia se mantiene estable y sin errores funcionales.

La carga de CPU con un solo proceso no altera de forma apreciable la medida. En cambio, ocupar ambos cores incrementa mucho la latencia y tambien la dispersion. Esto indica que la medida desde espacio de usuario no depende solo del hardware AXI4-Lite, sino tambien de la planificacion de Linux y de la disponibilidad de CPU.

La carga de I/O sobre la SD no afecta directamente al periferico AXI4-Lite, pero si introduce un incremento moderado de latencia. Esta prueba sirve para explicar que las medidas hechas desde Linux pueden verse afectadas por actividad del sistema, aunque en este caso el impacto es mucho menor que con CPU 2 cores.

Todas las campaigns tienen `mismatches = 0`, por lo que no se han detectado errores funcionales en el camino PS -> AXI -> PL -> AXI -> PS durante las pruebas.

## Documentos de esta carpeta

- [A_idle_1h.md](A_idle_1h.md): referencia de 1 hora en reposo.
- [B_idle_5h.md](B_idle_5h.md): estabilidad de larga duracion.
- [C_cpu_load.md](C_cpu_load.md): comparacion con carga de CPU.
- [D_sd_io_1h.md](D_sd_io_1h.md): carga de I/O sobre SD.
- [E_scale_iters.md](E_scale_iters.md): escala de iteraciones.
- [F_trace_detail.md](F_trace_detail.md): microtrazas y coste de instrumentacion.
- [comparisons.md](comparisons.md): comparaciones recomendadas para la memoria.
- [tfg-writing-guide.md](tfg-writing-guide.md): guia para redactar esta parte del TFG.
