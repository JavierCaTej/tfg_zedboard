function t12_plot_campaign(campaign_dir, output_dir, run_number)
% Genera las graficas de una campaign T12.
%
% Ejemplo normal:
% addpath('measurements/octave')
% t12_plot_campaign('measurements/t12/A_idle_1h')
%
% Por defecto no guarda nada dentro de measurements/t12, porque ahi quiero
% mantener los datos en bruto. Los resultados procesados se guardan en:
%
% measurements/t12_analysis/<campaign>/plots
% measurements/t12_analysis/<campaign>/data

  if nargin < 1
    error("Uso: t12_plot_campaign('measurements/t12/A_idle_1h')");
  endif

  % Leo todos los CSV de la campaign. Esta funcion me devuelve ya ordenados
  % los datos de cada run.
  data = t12_read_campaign(campaign_dir);

  % Si no indico carpeta de salida, uso una carpeta generada a partir del
  % nombre de la campaign.
  if nargin < 2 || isempty(output_dir)
    output_dir = fullfile("measurements", "t12_analysis", data.name);
  endif

  % Por defecto dibujo el primer run en la grafica detallada. Si quiero otro,
  % puedo pasarlo como tercer parametro.
  if nargin < 3
    run_number = 1;
  endif

  plots_dir = fullfile(output_dir, "plots");
  data_dir = fullfile(output_dir, "data");

  ensure_dir(plots_dir);
  ensure_dir(data_dir);

  % Guardo tambien CSV procesados. Asi si luego meto una grafica en la memoria,
  % queda claro de que datos sale.
  write_campaign_summary(data, fullfile(data_dir, "campaign_summary.csv"));
  write_trace_stats(data, fullfile(data_dir, "trace_stats_by_run.csv"));

  plot_run_avg_vs_time(data, fullfile(plots_dir, "01_runs_avg_vs_time.png"));
  plot_hist_run_avg(data, fullfile(plots_dir, "02_hist_run_avg.png"));
  plot_trace_one_run(data, run_number, ...
                     fullfile(plots_dir, "03_trace_one_run.png"), ...
                     fullfile(data_dir, sprintf("trace_run_%03d.csv", run_number)));
  plot_trace_full_campaign(data, ...
                           fullfile(plots_dir, "04_trace_full_campaign.png"), ...
                           fullfile(data_dir, "trace_full_campaign_sampled.csv"));
  plot_trace_stats_by_run(data, fullfile(plots_dir, "05_trace_stats_by_run.png"));

  printf("Graficas guardadas en %s\n", plots_dir);
  printf("Datos procesados guardados en %s\n", data_dir);
endfunction

function write_campaign_summary(data, output_file)
  % Este CSV resume cada run en una sola fila. Es el fichero que usaria para
  % tablas de la memoria: media, tiempo total, mismatches, etc.
  fid = fopen(output_file, "w");
  if fid < 0
    error("No se puede escribir %s", output_file);
  endif

  fprintf(fid, "run,run_dir,avg_ns,elapsed_s,mismatches,trace_blocks,trace_mean_ns,trace_min_ns,trace_max_ns,trace_std_ns,trace_mismatches\n");

  for i = 1:rows(data.summary)
    fprintf(fid, "%d,%s,%.3f,%.6f,%.0f,%.0f,%.3f,%.3f,%.3f,%.3f,%.0f\n", ...
            data.summary(i, 1), data.run_dirs{i}, data.summary(i, 6), ...
            data.summary(i, 8), data.summary(i, 7), ...
            data.trace_stats(i, 2), data.trace_stats(i, 3), ...
            data.trace_stats(i, 4), data.trace_stats(i, 5), ...
            data.trace_stats(i, 6), data.trace_stats(i, 7));
  endfor

  fclose(fid);
endfunction

function write_trace_stats(data, output_file)
  % Este CSV se centra solo en los trace-block. Me interesa para ver si dentro
  % de cada run aparecen bloques mas lentos, mas rapidos o con mas dispersion.
  fid = fopen(output_file, "w");
  if fid < 0
    error("No se puede escribir %s", output_file);
  endif

  fprintf(fid, "run,run_dir,n_blocks,mean_avg_ns,min_avg_ns,max_avg_ns,std_avg_ns,mismatches,elapsed_s\n");

  for i = 1:rows(data.trace_stats)
    fprintf(fid, "%d,%s,%.0f,%.3f,%.3f,%.3f,%.3f,%.0f,%.6f\n", ...
            data.trace_stats(i, 1), data.run_dirs{i}, data.trace_stats(i, 2), ...
            data.trace_stats(i, 3), data.trace_stats(i, 4), ...
            data.trace_stats(i, 5), data.trace_stats(i, 6), ...
            data.trace_stats(i, 7), data.trace_stats(i, 8));
  endfor

  fclose(fid);
endfunction

function plot_run_avg_vs_time(data, output_file)
  % Grafica principal de estabilidad: cada punto es una repeticion completa.
  % El eje X no es el numero de run, sino el tiempo acumulado de campaign.
  x_hours = cumsum(data.summary(:, 8)) / 3600.0;
  y = data.summary(:, 6);

  fig = figure("visible", "off");
  plot(x_hours, y, "-o", "linewidth", 1.2, "markersize", 3);
  grid on;
  xlabel("tiempo acumulado de campaign (h)");
  ylabel("latencia media por run (ns)");
  title(sprintf("%s: avg\\_ns por run", data.name), "interpreter", "none");
  print(fig, output_file, "-dpng", "-r150");
  close(fig);
endfunction

function plot_hist_run_avg(data, output_file)
  % Histograma simple para ver si los runs se agrupan mucho o si hay mucha
  % dispersion.
  y = data.summary(:, 6);

  fig = figure("visible", "off");
  hist(y, 20);
  grid on;
  xlabel("latencia media por run (ns)");
  ylabel("numero de runs");
  title(sprintf("%s: distribucion de avg\\_ns", data.name), "interpreter", "none");
  print(fig, output_file, "-dpng", "-r150");
  close(fig);
endfunction

function plot_trace_one_run(data, run_number, output_file, csv_output_file)
  % Esta grafica entra dentro de un solo run. Cada punto representa un bloque
  % de trace-block, no una iteracion individual.
  if run_number < 1 || run_number > numel(data.run_dirs)
    error("run_number fuera de rango");
  endif

  run_dir = fullfile(data.path, data.run_dirs{run_number});
  trace_file = find_trace_for_plot(run_dir);

  if isempty(trace_file)
    warning("No hay CSV trace-block en %s", run_dir);
    return;
  endif

  t = dlmread(trace_file, ",", 1, 0);
  x_seconds = cumsum(t(:, 4)) / 1e9;
  y = t(:, 5);

  % Guardo el CSV ya preparado para esta grafica.
  fid = fopen(csv_output_file, "w");
  fprintf(fid, "time_s,block,first_iter,iters,elapsed_ns,avg_ns,mismatches\n");
  for i = 1:rows(t)
    fprintf(fid, "%.9f,%.0f,%.0f,%.0f,%.0f,%.3f,%.0f\n", ...
            x_seconds(i), t(i, 1), t(i, 2), t(i, 3), t(i, 4), t(i, 5), t(i, 6));
  endfor
  fclose(fid);

  fig = figure("visible", "off");
  plot(x_seconds, y, "linewidth", 1.0);
  grid on;
  xlabel("tiempo dentro del run (s)");
  ylabel("latencia media del bloque (ns)");
  title(sprintf("%s %s: trace-block", data.name, data.run_dirs{run_number}), "interpreter", "none");
  print(fig, output_file, "-dpng", "-r150");
  close(fig);
endfunction

function plot_trace_full_campaign(data, output_file, csv_output_file)
  % Junta todos los trace-block de la campaign. Si hay demasiados puntos,
  % reduzco la cantidad que dibujo para que la imagen no pese demasiado.
  max_points = 200000;
  x_all = [];
  y_all = [];
  offset_s = 0;

  for i = 1:numel(data.run_dirs)
    run_dir = fullfile(data.path, data.run_dirs{i});
    trace_file = find_trace_for_plot(run_dir);

    if isempty(trace_file)
      continue;
    endif

    t = dlmread(trace_file, ",", 1, 0);
    x = offset_s + cumsum(t(:, 4)) / 1e9;
    y = t(:, 5);

    x_all = [x_all; x];
    y_all = [y_all; y];
    offset_s = offset_s + sum(t(:, 4)) / 1e9;
  endfor

  if isempty(x_all)
    warning("No hay trazas para %s", data.name);
    return;
  endif

  step = max(1, ceil(numel(x_all) / max_points));
  idx = 1:step:numel(x_all);

  % Guardo el mismo subconjunto que dibujo. Si no se reduce nada, se guarda
  % todo.
  fid = fopen(csv_output_file, "w");
  fprintf(fid, "time_h,avg_ns\n");
  for i = idx
    fprintf(fid, "%.9f,%.3f\n", x_all(i) / 3600.0, y_all(i));
  endfor
  fclose(fid);

  fig = figure("visible", "off");
  plot(x_all(idx) / 3600.0, y_all(idx), ".", "markersize", 2);
  grid on;
  xlabel("tiempo acumulado de campaign (h)");
  ylabel("latencia media por bloque (ns)");
  title(sprintf("%s: trace-block de toda la campaign", data.name), "interpreter", "none");
  print(fig, output_file, "-dpng", "-r150");
  close(fig);
endfunction

function plot_trace_stats_by_run(data, output_file)
  % Comparo media, minimo y maximo de los bloques de cada run. Es util para
  % ver si algun run tuvo picos raros aunque su media general parezca normal.
  x = data.summary(:, 1);
  mean_y = data.trace_stats(:, 3);
  min_y = data.trace_stats(:, 4);
  max_y = data.trace_stats(:, 5);

  fig = figure("visible", "off");
  plot(x, mean_y, "-o", "linewidth", 1.2, "markersize", 3);
  hold on;
  plot(x, min_y, "--", "linewidth", 0.8);
  plot(x, max_y, "--", "linewidth", 0.8);
  hold off;
  grid on;
  xlabel("run");
  ylabel("latencia por bloque (ns)");
  legend("media", "minimo", "maximo", "location", "best");
  title(sprintf("%s: estadisticos de trace-block por run", data.name), "interpreter", "none");
  print(fig, output_file, "-dpng", "-r150");
  close(fig);
endfunction

function trace_file = find_trace_for_plot(run_dir)
  % Devuelve el primer trace-block que encuentre dentro del run. En mis
  % campaign deberia haber solo uno.
  files = dir(fullfile(run_dir, "*_trace_*.csv"));
  if isempty(files)
    trace_file = "";
  else
    trace_file = fullfile(run_dir, files(1).name);
  endif
endfunction

function ensure_dir(path)
  % mkdir normal falla si falta una carpeta intermedia. Esta funcion crea los
  % padres antes, parecido a mkdir -p.
  if exist(path, "dir") == 7
    return;
  endif

  parent = fileparts(path);
  if !isempty(parent) && exist(parent, "dir") != 7
    ensure_dir(parent);
  endif

  mkdir(path);
endfunction
