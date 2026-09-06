# Campaign E - Escala de iteraciones

## Objetivo

La campaign E justifica el numero de iteraciones elegido para las medidas largas. Se ejecutan varias campaigns en reposo cambiando el tamaño del bucle `rw-loop`.

El objetivo es comprobar si usar pocas iteraciones produce mas ruido y si al aumentar el numero de iteraciones la media se estabiliza.

## Resultados

| Campaign | Iteraciones | Runs | Media `avg_ns` | Std | Min | Max | Mismatches |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `E_scale_iters_001_1M` | 1M | 20 | 335.650 ns | 0.186 | 335.366 | 335.928 | 0 |
| `E_scale_iters_002_10M` | 10M | 20 | 335.276 ns | 0.060 | 335.168 | 335.378 | 0 |
| `E_scale_iters_003_100M` | 100M | 20 | 335.259 ns | 0.020 | 335.227 | 335.296 | 0 |
| `E_scale_iters_004_180M` | 180M | 20 | 335.260 ns | 0.015 | 335.233 | 335.281 | 0 |

## Interpretacion

Con `1M` iteraciones la media queda algo mas alta y la desviacion tipica es mayor. Al subir a `10M`, `100M` y `180M`, la media converge a aproximadamente `335.26 ns`.

La desviacion tipica baja de `0.186 ns` en `1M` a `0.015 ns` en `180M`. Esto confirma que las campaigns largas reducen el ruido relativo y hacen la medida mas estable.

El resultado de `100M` ya es muy cercano al de `180M`, por lo que `180M` no cambia la media, pero da una base aun mas estable para las campaigns de 1 hora. Esto justifica usar `180000000` iteraciones en A, B, C y D.

## Graficas recomendadas

- `measurements/t12_analysis/comparison_E_scale/plots/01_comparison_mean_std.png`
- `measurements/t12_analysis/comparison_E_scale/plots/02_comparison_all_runs.png`
- `measurements/t12_analysis/comparison_E_scale/plots/03_comparison_histograms.png`

## Frase util para la memoria

La escala de iteraciones muestra que la latencia media converge hacia `335.26 ns` al aumentar el tamaño de muestra, y que la dispersion disminuye de forma clara. Por ello, las campaigns principales se ejecutan con `180M` iteraciones por run.
