# Resultado de simulación T3

## Propósito general

La simulación valida reset, lectura/escritura, eco `WDATA/RDATA`, contadores y limpieza por `REG_CONTROL[0]`.

## Evidencias guardadas

- Captura de waveform: `hw/ip/tfg_axi_lite_regs_1_0/tb/tb_tfg_axi_lite_regs_v1_0.png`
- Configuración de waveform: `hw/ip/tfg_axi_lite_regs_1_0/tb/tb_tfg_axi_lite_regs_v1_0_behav.wcfg`
- Testbench usado: `hw/ip/tfg_axi_lite_regs_1_0/tb/tb_tfg_axi_lite_regs_v1_0.vhd`

## Casos comprobados

- Caso 1: lectura de `REG_ID` tras reset. Resultado: `PASS`
- Caso 2: lectura de `REG_VERSION` tras reset. Resultado: `PASS`
- Caso 3: lectura de `REG_STATUS` tras reset (`READY = 1`). Resultado: `PASS`
- Caso 4: escritura de `REG_WDATA` con `0x12345678`. Resultado: `PASS`
- Caso 5: lectura de `REG_RDATA` con eco de `REG_WDATA`. Resultado: `PASS`
- Caso 6: lectura de `REG_WRITE_COUNT` tras la primera escritura. Resultado: `PASS`
- Caso 7: lectura de `REG_READ_COUNT` tras la primera lectura de `REG_RDATA`. Resultado: `PASS`
- Caso 8: segunda escritura de `REG_WDATA` con `0xBEBECAFE`. Resultado: `PASS`
- Caso 9: segunda lectura de `REG_RDATA` con eco del último valor escrito. Resultado: `PASS`
- Caso 10: lectura de `REG_WRITE_COUNT` tras la segunda escritura. Resultado: `PASS`
- Caso 11: lectura de `REG_READ_COUNT` tras la segunda lectura de `REG_RDATA`. Resultado: `PASS`
- Caso 12: lectura de un offset no implementado con valor `0`. Resultado: `PASS`
- Caso 13: primera lectura de `REG_COUNTER_L`. Resultado: `PASS`
- Caso 14: segunda lectura de `REG_COUNTER_L` con incremento entre lecturas. Resultado: `PASS`
- Caso 15: lectura de `REG_COUNTER_H` en simulación corta con valor `0`. Resultado: `PASS`
- Caso 16: escritura de `REG_CONTROL[0]` para limpiar contadores. Resultado: `PASS`
- Caso 17: comprobación de borrado de `REG_WRITE_COUNT`. Resultado: `PASS`
- Caso 18: comprobación de borrado de `REG_READ_COUNT`. Resultado: `PASS`

## Conclusión breve

La simulación funcional cubre los casos mínimos de `T3.23` y deja evidencia suficiente para `T3.25` mediante waveform, captura y resumen de resultados.
