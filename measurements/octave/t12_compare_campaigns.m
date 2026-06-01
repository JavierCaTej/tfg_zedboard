function t12_compare_campaigns(campaign_dirs, output_dir)
% Compara varias campaign T12 usando los CSV resumen.
%
% Ejemplo:
% addpath('measurements/octave')
% t12_compare_campaigns({
%   'measurements/t12/A_idle_1h',
%   'measurements/t12/B_idle_5h',
%   'measurements/t12/C_cpu_1core_1h',
%   'measurements/t12/C_cpu_2core_1h'
% })
%
% La salida se guarda por defecto en:
%
% measurements/t12_analysis/comparison/plots
% measurements/t12_analysis/comparison/data

  % Si no paso ninguna lista, uso las campaign principales que estoy midiendo.
  if nargin < 1
    campaign_dirs = {
      "measurements/t12/A_idle_1h",
      "measurements/t12/B_idle_5h",
      "measurements/t12/C_cpu_1core_1h",
      "measurements/t12/C_cpu_2core_1h"
    };
  endif

  if nargin < 2 || isempty(output_dir)
    output_dir = fullfile("measurements", "t12_analysis", "comparison");
  endif

  plots_dir = fullfile(output_dir, "plots");
  data_dir = fullfile(output_dir, "data");

  ensure_dir(plots_dir);
  ensure_dir(data_dir);

  n = numel(campaign_dirs);
  data = cell(n, 1);

  % Leo todas las campaign primero. Asi las funciones de graficas trabajan
  % siempre con la misma estructura.
  for i = 1:n
    data{i} = t12_read_campaign(campaign_dirs{i});
  endfor

  write_comparison_csv(data, fullfile(data_dir, "comparison_summary.csv"));
  write_all_runs_csv(data, fullfile(data_dir, "comparison_all_runs.csv"));

  plot_mean_std(data, fullfile(plots_dir, "01_comparison_mean_std.png"));
  plot_all_runs(data, fullfile(plots_dir, "02_comparison_all_runs.png"));
  plot_histograms(data, fullfile(plots_dir, "03_comparison_histograms.png"));

  printf("Graficas de comparacion guardadas en %s\n", plots_dir);
  printf("Datos de comparacion guardados en %s\n", data_dir);
endfunction

function write_comparison_csv(data, output_file)
  % Este CSV es la tabla resumen por campaign. Es muy util para meter una tabla
  % en la memoria: media, desviacion, minimo, maximo y mismatches.
  fid = fopen(output_file, "w");
  if fid < 0
    error("No se puede escribir %s", output_file);
  endif

  fprintf(fid, "campaign,runs,mean_avg_ns,std_avg_ns,min_avg_ns,max_avg_ns,total_elapsed_h,total_mismatches\n");

  for i = 1:numel(data)
    y = data{i}.summary(:, 6);
    elapsed_h = sum(data{i}.summary(:, 8)) / 3600.0;
    mismatches = sum(data{i}.summary(:, 7));

    fprintf(fid, "%s,%d,%.3f,%.3f,%.3f,%.3f,%.6f,%.0f\n", ...
            data{i}.name, numel(y), mean(y), std(y), min(y), max(y), ...
            elapsed_h, mismatches);
  endfor

  fclose(fid);
endfunction

function write_all_runs_csv(data, output_file)
  % Este CSV junta todos los runs de todas las campaign. Lo guardo porque
  % ayuda a comprobar de forma rapida que puntos se han dibujado.
  fid = fopen(output_file, "w");
  if fid < 0
    error("No se puede escribir %s", output_file);
  endif

  fprintf(fid, "campaign,run,time_h,avg_ns,elapsed_s,mismatches\n");

  for i = 1:numel(data)
    x_hours = cumsum(data{i}.summary(:, 8)) / 3600.0;

    for j = 1:rows(data{i}.summary)
      fprintf(fid, "%s,%d,%.9f,%.3f,%.6f,%.0f\n", ...
              data{i}.name, data{i}.summary(j, 1), x_hours(j), ...
              data{i}.summary(j, 6), data{i}.summary(j, 8), ...
              data{i}.summary(j, 7));
    endfor
  endfor

  fclose(fid);
endfunction

function plot_mean_std(data, output_file)
  % Barras con media y desviacion tipica. Es una de las graficas mas claras
  % para comparar reposo contra carga de CPU.
  n = numel(data);
  means = zeros(n, 1);
  stds = zeros(n, 1);
  labels = cell(n, 1);

  for i = 1:n
    y = data{i}.summary(:, 6);
    means(i) = mean(y);
    stds(i) = std(y);
    labels{i} = data{i}.name;
  endfor

  fig = figure("visible", "off");
  bar(1:n, means);
  hold on;
  % En Octave es mas seguro crear primero el errorbar y despues cambiar el
  % grosor con set. Si se meten propiedades directamente, algunas versiones
  % fallan interpretando los argumentos.
  h = errorbar(1:n, means, stds, ".k");
  set(h, "linewidth", 1.2);
  hold off;
  grid on;
  set(gca, "xtick", 1:n, "xticklabel", labels);
  if exist("xtickangle", "file") || exist("xtickangle", "builtin")
    xtickangle(25);
  endif
  ylabel("latencia media por run (ns)");
  title("Comparacion de campaigns: media y desviacion tipica", "interpreter", "none");
  print(fig, output_file, "-dpng", "-r150");
  close(fig);
endfunction

function plot_all_runs(data, output_file)
  % Aqui pongo todas las campaigns en la misma figura. El eje X es el tiempo
  % acumulado dentro de cada campaign, no el tiempo absoluto real.
  fig = figure("visible", "off");
  hold on;

  for i = 1:numel(data)
    x = cumsum(data{i}.summary(:, 8)) / 3600.0;
    y = data{i}.summary(:, 6);
    plot(x, y, "-o", "linewidth", 1.0, "markersize", 2);
  endfor

  hold off;
  grid on;
  xlabel("tiempo acumulado dentro de cada campaign (h)");
  ylabel("latencia media por run (ns)");
  title("Comparacion de avg\\_ns por run", "interpreter", "none");
  legend(get_names(data), "location", "best");
  print(fig, output_file, "-dpng", "-r150");
  close(fig);
endfunction

function plot_histograms(data, output_file)
  % Histograma normalizado. No busco contar cuantos runs hay, sino comparar la
  % forma de la distribucion entre campaign.
  fig = figure("visible", "off");
  hold on;

  for i = 1:numel(data)
    y = data{i}.summary(:, 6);
    [counts, centers] = hist(y, 20);
    counts = counts / sum(counts);
    plot(centers, counts, "linewidth", 1.2);
  endfor

  hold off;
  grid on;
  xlabel("latencia media por run (ns)");
  ylabel("frecuencia relativa");
  title("Distribucion de latencias por campaign", "interpreter", "none");
  legend(get_names(data), "location", "best");
  print(fig, output_file, "-dpng", "-r150");
  close(fig);
endfunction

function names = get_names(data)
  names = cell(numel(data), 1);

  for i = 1:numel(data)
    names{i} = data{i}.name;
  endfor
endfunction

function ensure_dir(path)
  % Version sencilla de mkdir -p para Octave.
  if exist(path, "dir") == 7
    return;
  endif

  parent = fileparts(path);
  if !isempty(parent) && exist(parent, "dir") != 7
    ensure_dir(parent);
  endif

  mkdir(path);
endfunction
