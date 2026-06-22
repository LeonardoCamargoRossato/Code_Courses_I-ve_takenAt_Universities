%gera_tabela_deIndicadores_total_e_filtrada

function [tabela_resultado, tabela_filtrada] = gerar_tabela_grid_Kp_Ki()

clc;
close all;

% ===============================
% VETORES DE ENTRADA
% ===============================
Kp_vec = round((-1.9:0.1:2.9), 4);
Ki_vec = round((0.1:0.1:2.0), 4);

% Total esperado: 10 Ki x 12 Kp = 120 linhas
n_linhas_esperado = length(Kp_vec)*length(Ki_vec);

% ===============================
% PASTA DE SAÍDA
% ===============================
pasta_saida = fullfile(pwd, 'tabela_result_grid_Kp_Ki');

if ~exist(pasta_saida, 'dir')
    mkdir(pasta_saida);
end

% ===============================
% SISTEMA DO ENUNCIADO
% ===============================
A = [-3 -2; 1 0];
B = [1; 0];
C = [-1 1];
D = 0;

Sistema = ss(A,B,C,D);

% ===============================
% MATRIZ DE RESULTADOS
% Colunas:
% Kp, Ki, Ki_max, ValidoRegiao, Estavel,
% TempoSubida, Overshoot, Undershoot, ErroRampa
% ===============================
resultados = [];

for i = 1:length(Ki_vec)

    Ki = Ki_vec(i);

    for j = 1:length(Kp_vec)

        Kp = Kp_vec(j);

        Ki_max = ((Kp - 3)*(Kp + 2))/(Kp - 4);

        ValidoRegiao = (Kp > -2) && (Kp < 3) && (Ki > 0) && (Ki < Ki_max);

        [TempoSubida, Overshoot, Undershoot, ErroRampa, Estavel] = calcula_indicadores_local(Kp, Ki, Sistema);

        resultados = [resultados; ...
            Kp Ki Ki_max ValidoRegiao Estavel TempoSubida Overshoot Undershoot ErroRampa];

    end
end

% ===============================
% CONVERTENDO PARA TABELA
% ===============================
tabela_resultado = array2table(resultados, ...
    'VariableNames', { ...
    'Kp', ...
    'Ki', ...
    'Ki_max', ...
    'ValidoRegiao', ...
    'Estavel', ...
    'TempoSubida', ...
    'Overshoot', ...
    'Undershoot', ...
    'ErroRampa' ...
    });

% ===============================
% SALVANDO TABELA COMPLETA
% ===============================
arquivo_completo_csv = fullfile(pasta_saida, 'tabela_completa_120_linhas.csv');
arquivo_completo_mat = fullfile(pasta_saida, 'tabela_completa_120_linhas.mat');

writetable(tabela_resultado, arquivo_completo_csv);
save(arquivo_completo_mat, 'tabela_resultado');

% ===============================
% FILTRO DE DESEMPENHO
% ===============================
idx_filtro = ...
    tabela_resultado.ValidoRegiao == 1 & ...
    tabela_resultado.Estavel == 1 & ...
    ~isnan(tabela_resultado.TempoSubida) & ...
    ~isnan(tabela_resultado.Overshoot) & ...
    ~isnan(tabela_resultado.Undershoot) & ...
    ~isnan(tabela_resultado.ErroRampa) & ...
    tabela_resultado.TempoSubida <= 10 & ...
    tabela_resultado.Overshoot <= 0.25 & ...
    tabela_resultado.Undershoot <= 0.15 & ...
    tabela_resultado.ErroRampa <= 5;

tabela_filtrada = tabela_resultado(idx_filtro,:);

% ===============================
% SALVANDO TABELA FILTRADA
% ===============================
arquivo_filtrado_csv = fullfile(pasta_saida, 'tabela_filtrada_criterios_bons.csv');
arquivo_filtrado_mat = fullfile(pasta_saida, 'tabela_filtrada_criterios_bons.mat');

writetable(tabela_filtrada, arquivo_filtrado_csv);
save(arquivo_filtrado_mat, 'tabela_filtrada');

% ===============================
% MOSTRANDO RESULTADOS
% ===============================
disp('Tabela completa gerada:')
disp(tabela_resultado)

disp('Tabela filtrada:')
disp(tabela_filtrada)

fprintf('\nNúmero esperado de linhas: %d\n', n_linhas_esperado);
fprintf('Número de linhas da tabela completa: %d\n', height(tabela_resultado));
fprintf('Número de linhas da tabela filtrada: %d\n', height(tabela_filtrada));

disp('Arquivos salvos na pasta:')
disp(pasta_saida)

end


% =====================================================
% FUNÇÃO LOCAL PARA CALCULAR OS 4 INDICADORES
% =====================================================
function [TempoSubida, Overshoot, Undershoot, ErroRampa, Estavel] = calcula_indicadores_local(Kp, Ki, Sistema)

TempoSubida = NaN;
Overshoot = NaN;
Undershoot = NaN;
ErroRampa = NaN;
Estavel = 0;

try

    % Controlador PI:
    % C(s) = Kp + Ki/s = (Kp*s + Ki)/s
    Controlador = tf([Kp Ki], [1 0]);

    % Malha fechada
    H = feedback(Sistema*Controlador, 1);

    % Verifica estabilidade
    Estavel = isstable(H);

    if Estavel == 0
        return;
    end

    % Tempo de simulação
    t = 0:0.01:20;

    % ===============================
    % RESPOSTA AO DEGRAU
    % ===============================
    [y_degrau, t_degrau] = step(H, t);

    % Tempo de subida: primeiro instante em que y(t) chega a 90% da referência
    idx = find(y_degrau >= 0.9, 1);

    if isempty(idx)
        TempoSubida = NaN;
    else
        TempoSubida = t_degrau(idx);
    end

    % Overshoot: quanto passa acima de 1
    Overshoot = max(0, max(y_degrau) - 1);

    % Undershoot: quanto cai abaixo de 0
    Undershoot = max(0, -min(y_degrau));

    % ===============================
    % RESPOSTA À RAMPA
    % ===============================
    rampa = t';
    y_rampa = lsim(H, rampa, t);

    % Erro final para entrada rampa
    ErroRampa = abs(rampa(end) - y_rampa(end));

catch

    TempoSubida = NaN;
    Overshoot = NaN;
    Undershoot = NaN;
    ErroRampa = NaN;
    Estavel = 0;

end

end