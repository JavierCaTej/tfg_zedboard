function t12_plot_trace_detail(trace_dir, output_dir)
% Analiza la campaign F, que no tiene carpetas run_XX.
%
% En F guardo microtrazas cortas en carpetas como:
% measurements/t12/F_trace_detail/trace_idle
% measurements/t12/F_trace_detail/trace_cpu_2core
%
% Esta funcion detecta si el CSV es por iteracion o por bloques y genera una
% grafica para cada fichero. Tambien guarda un CSV resumen con media, minimo,
% maximo, desviacion tipica y mismatches.

  if nargin < 1
    error("Uso: t12_plot_trace_detail('measurements/t12/F_trace_detail/trace_idle')");
  endif

  [~, trace_name] = fileparts(trace_dir);

  if nargin < 2 || isempty(output_dir)
    output_dir = fullfile("measurements", "t12_analysis", "F_trace_detail", trace_name);
  endif

  plots_dir = fullfile(output_dir, "plots");
  data_dir = fullfile(output_dir, "data");

  ensure_dir(plots_dir);
  ensure_dir(data_dir);

  files = dir(fullfile(trace_dir, "*_trace_*.csv"));
  if isempty(files)
    error("No hay CSV de traza en %s", trace_dir);
  endif

  fid_summary = fopen(fullfile(data_dir, "trace_detail_summary.csv"), "w");
  if fid_summary < 0
    error("No se puede crear trace_detail_summary.csv");
  endif

  fprintf(fid_summary, "file,mode,rows,mean_ns,min_ns,max_ns,std_ns,total_elapsed_s,mismatches\n");

  for i = 1:numel(files)
    input_file = fullfile(trace_dir, files(i).name);
    [mode, x_s, y_ns, mismatches] = read_any_trace(input_file);

    total_elapsed_s = sum(y_ns) / 1e9;
    if strcmp(mode, "block")
      % En modo bloque y_ns ya es avg_ns, asi que el tiempo total se calcula
      % dentro de read_any_trace y se devuelve en x_s acumulado.
      total_elapsed_s = x_s(end);
    endif

    fprintf(fid_summary, "%s,%s,%d,%.3f,%.3f,%.3f,%.3f,%.9f,%.0f\n", ...
            files(i).name, mode, numel(y_ns), mean(y_ns), min(y_ns), ...
            max(y_ns), std(y_ns), total_elapsed_s, sum(mismatches));

    output_csv = fullfile(data_dir, sprintf("trace_%02d_%s.csv", i, mode));
    write_trace_for_plot(output_csv, x_s, y_ns, mismatches);

    output_png = fullfile(plots_dir, sprintf("trace_%02d_%s.png", i, mode));
    plot_one_trace(trace_name, files(i).name, mode, x_s, y_ns, output_png);
  endfor

  fclose(fid_summary);

  printf("Graficas F guardadas en %s\n", plots_dir);
  printf("Datos F guardados en %s\n", data_dir);
endfunction

function [mode, x_s, y_ns, mismatches] = read_any_trace(input_file)
  fid = fopen(input_file, "r");
  if fid < 0
    error("No se puede abrir %s", input_file);
  endif

  header = fgetl(fid);
  fclose(fid);

  raw = dlmread(input_file, ",", 1, 0);

  if !isempty(strfind(header, "iter,elapsed_ns,mismatch"))
    % Traza por iteracion. Cada fila es una iteracion medida una a una.
    mode = "iter";
    elapsed_ns = raw(:, 2);
    x_s = cumsum(elapsed_ns) / 1e9;
    y_ns = elapsed_ns;
    mismatches = raw(:, 3);
  elseif !isempty(strfind(header, "block,first_iter,iters,elapsed_ns,avg_ns,mismatches"))
    % Traza por bloques. Cada fila representa un bloque de N iteraciones.
    mode = "block";
    elapsed_ns = raw(:, 4);
    x_s = cumsum(elapsed_ns) / 1e9;
    y_ns = raw(:, 5);
    mismatches = raw(:, 6);
  else
    error("Cabecera de traza no reconocida en %s", input_file);
  endif
endfunction

function write_trace_for_plot(output_file, x_s, y_ns, mismatches)
  fid = fopen(output_file, "w");
  if fid < 0
    error("No se puede escribir %s", output_file);
  endif

  fprintf(fid, "time_s,latency_ns,mismatch\n");
  for i = 1:numel(y_ns)
    fprintf(fid, "%.9f,%.3f,%.0f\n", x_s(i), y_ns(i), mismatches(i));
  endfor

  fclose(fid);
endfunction

function plot_one_trace(trace_name, file_name, mode, x_s, y_ns, output_file)
  fig = figure("visible", "off");
  plot(x_s, y_ns, "linewidth", 1.0);
  grid on;
  xlabel("tiempo acumulado dentro de la traza (s)");

  if strcmp(mode, "iter")
    ylabel("latencia de cada iteracion (ns)");
  else
    ylabel("latencia media del bloque (ns)");
  endif

  title(sprintf("%s: %s", trace_name, file_name), "interpreter", "none");
  print(fig, output_file, "-dpng", "-r150");
  close(fig);
endfunction

function ensure_dir(path)
  if exist(path, "dir") == 7
    return;
  endif

  parent = fileparts(path);
  if !isempty(parent) && exist(parent, "dir") != 7
    ensure_dir(parent);
  endif

  mkdir(path);
endfunction
