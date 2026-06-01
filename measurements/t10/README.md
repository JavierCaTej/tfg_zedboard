# Medidas T10

Este directorio guarda las campañas de medida de `tfg_axi_memtool` para la tarea `T10`.

## Estructura recomendada

```text
measurements/t10/
measurements/t10/raw/
measurements/t10/summary/
```

## Flujo de uso

1. Copio los CSV generados por la ZedBoard a `measurements/t10/raw/`.
2. Lanzo el script de resumen para obtener una tabla con media, minimo y maximo.
3. Guardo el resultado final en `measurements/t10/summary/`.

## Comando de ejemplo

```bash
./measurements/t10/summarize_t10_csv.sh measurements/t10/raw/*.csv
```

El CSV de `rw-loop` contiene, entre otros campos:

- `elapsed_ns`: tiempo total de la campaña.
- `avg_ns`: media por iteracion.
- `mismatches`: errores funcionales. Para validar la medida debe ser `0`.

## Nota

Los CSV se consideran evidencia bruta. El resumen sirve para llevar luego los resultados a la memoria del TFG de forma mas limpia.
