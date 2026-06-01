function data = t12_read_campaign(campaign_dir)
% Lee una campaign T12 con el arbol que estoy usando en las medidas:
%
% measurements/t12/A_idle_1h/run_01/*.csv
% measurements/t12/A_idle_1h/run_02/*.csv
% ...
%
% Devuelve una estructura con:
% - summary: datos de los CSV resumen, una fila por run
% - trace_stats: resumen de los CSV trace-block, una fila por run
% - run_dirs: nombres de las carpetas run_XX encontradas
%
% La idea de esta funcion es dejar la lectura en un sitio separado. Asi los
% scripts de graficas no tienen que estar buscando ficheros CSV todo el rato.

  if nargin < 1
    error("Uso: data = t12_read_campaign('measurements/t12/A_idle_1h')");
  endif

  % Busco todas las carpetas run_XX. Cada una corresponde a una repeticion de
  % la campaign.
  run_list = dir(fullfile(campaign_dir, "run_*"));
  run_list = run_list([run_list.isdir]);

  if isempty(run_list)
    error("No se han encontrado carpetas run_* en %s", campaign_dir);
  endif

  % Ordeno por nombre para que run_001, run_002, ... salgan en orden.
  [~, order] = sort({run_list.name});
  run_list = run_list(order);

  n = numel(run_list);

  % Preparo las matrices. No uso tablas porque quiero que esto funcione en
  % Octave de forma sencilla.
  summary = zeros(n, 8);
  trace_stats = zeros(n, 8);
  run_dirs = cell(n, 1);

  for i = 1:n
    run_dir = fullfile(campaign_dir, run_list(i).name);
    run_dirs{i} = run_list(i).name;

    % En cada run tengo dos CSV: el resumen y, si se uso --trace-block, otro
    % CSV con los bloques. Primero localizo cada fichero.
    summary_file = find_summary_csv(run_dir);
    trace_file = find_trace_csv(run_dir);

    s = read_summary_csv(summary_file);

    % Columnas summary:
    % 1 run, 2 timestamp, 3 iters, 4 warmup, 5 elapsed_ns,
    % 6 avg_ns, 7 mismatches, 8 elapsed_s
    summary(i, :) = [i, s.timestamp, s.iters, s.warmup, ...
                     s.elapsed_ns, s.avg_ns, s.mismatches, ...
                     s.elapsed_ns / 1e9];

    if !isempty(trace_file)
      t = read_trace_csv(trace_file);

      % Columnas trace_stats:
      % 1 run, 2 n_blocks, 3 mean_avg_ns, 4 min_avg_ns, 5 max_avg_ns,
      % 6 std_avg_ns, 7 mismatches, 8 elapsed_s
      trace_stats(i, :) = [i, rows(t), mean(t(:, 5)), min(t(:, 5)), ...
                           max(t(:, 5)), std(t(:, 5)), sum(t(:, 6)), ...
                           sum(t(:, 4)) / 1e9];
    else
      % Algunas campaign pueden no tener trace-block. En ese caso dejo NaN
      % para que luego las graficas sepan que no hay datos de traza.
      trace_stats(i, :) = [i, 0, NaN, NaN, NaN, NaN, NaN, NaN];
    endif
  endfor

  % Devuelvo todo junto en una estructura. Asi despues puedo hacer:
  % data.summary, data.trace_stats, etc.
  [~, campaign_name] = fileparts(campaign_dir);
  data.name = campaign_name;
  data.path = campaign_dir;
  data.run_dirs = run_dirs;
  data.summary = summary;
  data.trace_stats = trace_stats;
endfunction

function csv_file = find_summary_csv(run_dir)
  % El CSV resumen no contiene "_trace_" en el nombre. Es el que tiene una
  % unica fila con avg_ns, elapsed_ns, mismatches, etc.
  files = dir(fullfile(run_dir, "*.csv"));
  csv_file = "";

  for i = 1:numel(files)
    name = files(i).name;
    if isempty(strfind(name, "_trace_"))
      csv_file = fullfile(run_dir, name);
      return;
    endif
  endfor

  error("No se ha encontrado CSV resumen en %s", run_dir);
endfunction

function csv_file = find_trace_csv(run_dir)
  % El CSV de trace-block si contiene "_trace_". Puede no existir si la
  % campaign se lanzo sin --trace-block.
  files = dir(fullfile(run_dir, "*_trace_*.csv"));

  if isempty(files)
    csv_file = "";
  else
    csv_file = fullfile(run_dir, files(1).name);
  endif
endfunction

function s = read_summary_csv(csv_file)
  % Los CSV resumen son muy pequenos: cabecera + una fila. Por eso los leo a
  % mano, separando por comas.
  fid = fopen(csv_file, "r");
  if fid < 0
    error("No se puede abrir %s", csv_file);
  endif

  header = fgetl(fid);
  line = fgetl(fid);
  fclose(fid);

  % No uso header ahora mismo, pero lo leo para saltarme la primera linea.
  % Dejo esta linea para que Octave no se queje por variable sin usar.
  header = header;

  if !ischar(line)
    error("CSV resumen vacio: %s", csv_file);
  endif

  parts = strsplit(line, ",");
  if numel(parts) < 10
    error("CSV resumen con formato inesperado: %s", csv_file);
  endif

  s.timestamp = str2double(parts{1});
  s.iters = str2double(parts{6});
  s.warmup = str2double(parts{7});
  s.elapsed_ns = str2double(parts{8});
  s.avg_ns = str2double(parts{9});
  s.mismatches = str2double(parts{10});
endfunction

function data = read_trace_csv(csv_file)
  % El trace-block ya tiene muchas filas, asi que aqui uso dlmread saltando la
  % cabecera. Las columnas son:
  % block, first_iter, iters, elapsed_ns, avg_ns, mismatches
  data = dlmread(csv_file, ",", 1, 0);

  if columns(data) != 6
    error("CSV trace-block con formato inesperado: %s", csv_file);
  endif
endfunction
