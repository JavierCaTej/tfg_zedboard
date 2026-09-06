# Guia para redactar T12 en la memoria del TFG

Este documento propone como transformar las medidas de T12 en texto para la memoria. No es el texto final, sino una guia para que la redaccion sea coherente y no se limite a pegar graficas.

## Estructura recomendada del capitulo experimental

### 1. Contexto de la plataforma

Explicar brevemente:

- Se usa una ZedBoard con Zynq-7000.
- La PL contiene un periferico AXI4-Lite propio.
- Linux arranca desde una SD generada con Buildroot.
- U-Boot carga el bitstream antes de arrancar Linux.
- El periferico esta mapeado en `0x40000000`.
- La herramienta de usuario `tfg_axi_memtool` accede mediante `/dev/mem`.

Objetivo de esta seccion: dejar claro que el entorno hardware/software esta controlado.

### 2. Herramienta de medida

Explicar `tfg_axi_memtool`:

- `smoke`: valida que el periferico responde.
- `rw-loop`: escribe y lee de forma repetida.
- `--csv`: guarda resumen de la medida.
- `--trace-block`: guarda medias por bloques dentro del run.
- `mismatches`: comprueba errores funcionales.

Idea importante:

> La medida principal no es una lectura aislada, sino un ciclo completo de escritura, lectura y verificacion.

### 3. Metodologia

Explicar:

- Que es un run.
- Que es una campaign.
- Por que se usa warmup.
- Por que se usan 180M iteraciones en las campaigns principales.
- Por que se separan datos brutos (`measurements/t12`) y datos procesados (`measurements/t12_analysis`).
- Que Octave se usa para generar tablas y graficas reproducibles.

Incluir la campaign E para justificar el numero de iteraciones.

### 4. Resultados en reposo

Usar:

- `A_idle_1h`
- `B_idle_5h`

Mensaje principal:

> En reposo, la latencia media es aproximadamente `335 ns` y se mantiene estable durante 5 horas.

Graficas recomendadas:

- `A_idle_1h/plots/01_runs_avg_vs_time.png`
- `B_idle_5h/plots/01_runs_avg_vs_time.png`

### 5. Influencia de la carga del sistema

Usar:

- `C_cpu_1core_1h`
- `C_cpu_2core_1h`
- `D_sd_io_1h`

Mensaje principal:

> La carga de CPU a dos cores incrementa mucho la latencia, mientras que la carga de I/O sobre SD produce un incremento moderado. Esto demuestra que la medida desde Linux depende del contexto del sistema operativo.

Grafica principal:

- `comparison_loads_1h/plots/01_comparison_mean_std.png`

### 6. Analisis fino con trace-block

Usar:

- `07_trace_min_run.png`
- `07_trace_mean_run.png`
- `07_trace_max_run.png`
- `04_trace_full_campaign.png`

Mensaje principal:

> Las trazas por bloques ayudan a ver picos y dispersion dentro de cada run, pero la conclusion principal debe basarse en los CSV resumen.

### 7. Limitaciones

Mencionar:

- La medida se hace desde espacio de usuario, no desde driver kernel.
- Linux puede introducir variabilidad por planificacion e interrupciones.
- La temperatura no se ha podido medir de forma fiable.
- La carga de I/O sobre SD no permite sincronizar cada pico con cada escritura de `dd`.
- Las microtrazas por iteracion individual introducen overhead y no representan la latencia base.

### 8. Conclusiones

Conclusiones defendibles:

- El periferico funciona correctamente: `mismatches = 0` en todas las campaigns.
- La latencia base en reposo es de aproximadamente `335 ns`.
- La estabilidad temporal queda validada con 5 horas en reposo.
- El numero de iteraciones elegido queda justificado por la campaign E.
- La carga de CPU a dos cores incrementa la latencia un `52.5 %`.
- La carga de I/O sobre SD incrementa la latencia un `1.7 %`.
- Las condiciones del sistema operativo son relevantes en medidas desde Linux de usuario.

## Tablas recomendadas

Tabla principal:

```text
measurements/t12_analysis/comparison_loads_1h/data/comparison_summary.csv
```

Tabla de escala:

```text
measurements/t12_analysis/comparison_E_scale/data/comparison_summary.csv
```

Tabla de runs representativos:

```text
measurements/t12_analysis/<campaign>/data/representative_runs.csv
```

## Estilo recomendado

Evitar decir:

> La FPGA tarda 335 ns.

Mejor decir:

> El tiempo medio medido desde Linux para una iteracion `rw-loop` es de aproximadamente 335 ns.

Motivo: la medida incluye acceso desde usuario, `mmap`, planificacion del sistema, lectura/escritura AXI y comprobacion funcional. No es solo el retardo interno del hardware.

## Parrafo base para la memoria

> Para caracterizar el acceso al periferico AXI4-Lite se utilizo la herramienta `tfg_axi_memtool`, ejecutada desde Linux en la ZedBoard. La prueba principal fue `rw-loop`, que realiza una escritura seguida de una lectura y comprueba la coincidencia del dato. Las medidas se organizaron en campaigns con multiples runs y se almacenaron en CSV para su posterior analisis con GNU Octave. Los resultados muestran una latencia media en reposo de aproximadamente 335 ns por iteracion, sin errores funcionales detectados. Al introducir carga en ambos cores de CPU la latencia aumenta de forma significativa, mientras que la carga de I/O sobre la SD produce un incremento moderado. Esto confirma que el metodo de medida desde Linux es funcional, pero tambien sensible al contexto de ejecucion del sistema operativo.
