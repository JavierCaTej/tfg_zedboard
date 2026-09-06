#!/bin/sh

# Regenera todas las graficas y CSV procesados de T12.
# Lo lanzo desde la raiz del repositorio:
# sh measurements/octave/regenerate_t12_analysis.sh

set -eu

octave --quiet --no-history --eval "
addpath('measurements/octave');

t12_plot_campaign('measurements/t12/A_idle_1h');
t12_plot_campaign('measurements/t12/B_idle_5h');
t12_plot_campaign('measurements/t12/C_cpu_1core_1h');
t12_plot_campaign('measurements/t12/C_cpu_2core_1h');
t12_plot_campaign('measurements/t12/D_sd_io_1h');

t12_plot_campaign('measurements/t12/E_scale_iters_001_1M');
t12_plot_campaign('measurements/t12/E_scale_iters_002_10M');
t12_plot_campaign('measurements/t12/E_scale_iters_003_100M');
t12_plot_campaign('measurements/t12/E_scale_iters_004_180M');

t12_plot_trace_detail('measurements/t12/F_trace_detail/trace_idle');
t12_plot_trace_detail('measurements/t12/F_trace_detail/trace_cpu_2core');

t12_compare_campaigns({
  'measurements/t12/A_idle_1h',
  'measurements/t12/C_cpu_1core_1h',
  'measurements/t12/C_cpu_2core_1h',
  'measurements/t12/D_sd_io_1h'
}, 'measurements/t12_analysis/comparison_loads_1h');

t12_compare_campaigns({
  'measurements/t12/E_scale_iters_001_1M',
  'measurements/t12/E_scale_iters_002_10M',
  'measurements/t12/E_scale_iters_003_100M',
  'measurements/t12/E_scale_iters_004_180M'
}, 'measurements/t12_analysis/comparison_E_scale');

t12_plot_relative_change_vs_idle('measurements/t12_analysis/conclusions');
"
