clc;
clear;
close all;

% ===============================
% CAMINHO DO ARQUIVO CSV
% ===============================
pasta_entrada = fullfile(pwd, 'tabela_result_grid_Kp_Ki');
arquivo_csv = fullfile(pasta_entrada, 'tabela_filtrada_criterios_bons.csv');

% Verifica se o arquivo existe
if ~isfile(arquivo_csv)
    error('Arquivo não encontrado: %s', arquivo_csv);
end

% ===============================
% LENDO A TABELA
% ===============================
dados = readtable(arquivo_csv);

% Mostra primeiras linhas para conferência
disp('Primeiras linhas da tabela filtrada:')
disp(head(dados))

% ===============================
% SELECIONANDO OS 4 INDICADORES
% ===============================
indicadores = dados{:, {'TempoSubida', 'Overshoot', 'Undershoot', 'ErroRampa'}};

nomes_indicadores = {'TempoSubida', 'Overshoot', 'Undershoot', 'ErroRampa'};

% ===============================
% CRIANDO RÓTULOS DAS CURVAS
% Cada curva recebe o nome do par (Kp, Ki)
% ===============================
rotulos_curvas = strings(height(dados), 1);

for i = 1:height(dados)
    rotulos_curvas(i) = sprintf('(Kp=%.2f, Ki=%.2f)', dados.Kp(i), dados.Ki(i));
end

% ===============================
% PASTA DE SAÍDA
% ===============================
pasta_saida = fullfile(pwd, 'outputs_coordenadas_paralelas');

if ~exist(pasta_saida, 'dir')
    mkdir(pasta_saida);
end

% ===============================
% GRÁFICO DE COORDENADAS PARALELAS
% ===============================
fig = figure('Position', [100 100 1200 700]);

parallelcoords( ...
    indicadores, ...
    'Labels', nomes_indicadores, ...
    'Group', rotulos_curvas ...
    );

grid on;

title('Coordenadas Paralelas dos Indicadores - Tabela Filtrada');
ylabel('Valor dos indicadores');

% ===============================
% SALVANDO FIGURA
% ===============================
arquivo_png = fullfile(pasta_saida, 'coordenadas_paralelas_indicadores.png');
arquivo_fig = fullfile(pasta_saida, 'coordenadas_paralelas_indicadores.fig');

exportgraphics(fig, arquivo_png, 'Resolution', 300);
savefig(fig, arquivo_fig);

% ===============================
% SALVANDO TABELA USADA NO GRÁFICO
% ===============================
tabela_plot = dados(:, {'Kp', 'Ki', 'TempoSubida', 'Overshoot', 'Undershoot', 'ErroRampa'});
writetable(tabela_plot, fullfile(pasta_saida, 'dados_usados_coordenadas_paralelas.csv'));

% ===============================
% MENSAGEM FINAL
% ===============================
disp('Gráfico de coordenadas paralelas gerado com sucesso.')
disp('Arquivos salvos na pasta:')
disp(pasta_saida)