function t12_plot_relative_change_vs_idle(output_dir)
% Genera una figura de conclusiones comparando cada campaign contra A_idle_1h.
%
% La idea de esta grafica es usarla al final del analisis: no muestra todos
% los runs, sino el cambio porcentual de cada condicion respecto a reposo.
% Para que tambien se vean los cambios pequenos, hago dos paneles:
% - arriba: escala completa, donde se ve bien C_cpu_2core_1h
% - abajo: zoom de las variaciones pequenas

  if nargin < 1 || isempty(output_dir)
    output_dir = fullfile("measurements", "t12_analysis", "conclusions");
  endif

  plots_dir = fullfile(output_dir, "plots");
  data_dir = fullfile(output_dir, "data");
  ensure_dir(plots_dir);
  ensure_dir(data_dir);

  campaign_dirs = {
    "measurements/t12/A_idle_1h",
    "measurements/t12/B_idle_5h",
    "measurements/t12/C_cpu_1core_1h",
    "measurements/t12/C_cpu_2core_1h",
    "measurements/t12/D_sd_io_1h"
  };

  n = numel(campaign_dirs);
  names = cell(n, 1);
  mean_avg = zeros(n, 1);
  std_avg = zeros(n, 1);
  runs = zeros(n, 1);
  mismatches = zeros(n, 1);

  for i = 1:n
    data = t12_read_campaign(campaign_dirs{i});
    names{i} = data.name;
    y = data.summary(:, 6);
    mean_avg(i) = mean(y);
    std_avg(i) = std(y);
    runs(i) = rows(data.summary);
    mismatches(i) = sum(data.summary(:, 7));
  endfor

  ref = mean_avg(1);
  relative = ((mean_avg - ref) ./ ref) * 100.0;
  delta_ns = mean_avg - ref;

  write_relative_csv(fullfile(data_dir, "relative_change_vs_idle.csv"), ...
                     names, runs, mean_avg, std_avg, delta_ns, relative, mismatches);

  plot_relative(names, relative, delta_ns, ...
                fullfile(plots_dir, "01_relative_change_vs_idle.png"));

  printf("Figura de conclusiones guardada en %s\n", plots_dir);
  printf("CSV de conclusiones guardado en %s\n", data_dir);
endfunction

function write_relative_csv(output_file, names, runs, mean_avg, std_avg, delta_ns, relative, mismatches)
  fid = fopen(output_file, "w");
  if fid < 0
    error("No se puede escribir %s", output_file);
  endif

  fprintf(fid, "campaign,runs,mean_avg_ns,std_avg_ns,delta_vs_A_ns,relative_vs_A_percent,mismatches\n");
  for i = 1:numel(names)
    fprintf(fid, "%s,%.0f,%.3f,%.3f,%.3f,%.3f,%.0f\n", ...
            names{i}, runs(i), mean_avg(i), std_avg(i), ...
            delta_ns(i), relative(i), mismatches(i));
  endfor

  fclose(fid);
endfunction

function plot_relative(names, relative, delta_ns, output_file)
  x = 1:numel(names);

  fig = figure("visible", "off", "position", [100, 100, 1100, 750]);

  subplot(2, 1, 1);
  bar(x, relative);
  grid on;
  ylabel("variacion respecto a A_idle_1h (%)");
  title("Variacion relativa de la latencia media frente a A_idle_1h", ...
        "interpreter", "none");
  set(gca, "xtick", x, "xticklabel", names, "ticklabelinterpreter", "none");
  if exist("xtickangle", "file") || exist("xtickangle", "builtin")
    xtickangle(20);
  endif

  for i = 1:numel(names)
    text(x(i), relative(i), sprintf(" %.3f%%", relative(i)), ...
         "horizontalalignment", "center", "verticalalignment", "bottom", ...
         "interpreter", "none");
  endfor

  subplot(2, 1, 2);
  small_idx = [1, 2, 3, 5];
  bar(1:numel(small_idx), relative(small_idx));
  grid on;
  ylabel("variacion respecto a A_idle_1h (%)");
  title("Detalle ampliado de variaciones pequenas", "interpreter", "none");
  set(gca, "xtick", 1:numel(small_idx), "xticklabel", names(small_idx), ...
      "ticklabelinterpreter", "none");
  ylim([-0.2, 2.0]);
  if exist("xtickangle", "file") || exist("xtickangle", "builtin")
    xtickangle(20);
  endif

  for i = 1:numel(small_idx)
    idx = small_idx(i);
    text(i, relative(idx), sprintf(" %.3f%% / %.3f ns", relative(idx), delta_ns(idx)), ...
         "horizontalalignment", "center", "verticalalignment", "bottom", ...
         "interpreter", "none");
  endfor

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
