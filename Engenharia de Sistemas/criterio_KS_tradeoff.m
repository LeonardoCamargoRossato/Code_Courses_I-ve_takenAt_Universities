clc;
clear;
close all;

% ============================================================
% PASTA DE SAÍDA
% ============================================================
pasta_saida = fullfile(pwd, 'outputs_KS');

if ~exist(pasta_saida, 'dir')
    mkdir(pasta_saida);
end

% ============================================================
% ESCOLHA DO ARQUIVO DE ENTRADA
% ============================================================
% Preferencialmente usa a tabela completa, se ela existir.
% Caso contrário, usa a tabela filtrada.

arquivo_completo = fullfile(pwd, 'tabela_result_grid_Kp_Ki', 'tabela_completa_120_linhas.csv');
arquivo_filtrado = fullfile(pwd, 'tabela_result_grid_Kp_Ki', 'tabela_filtrada_criterios_bons.csv');
arquivo_coordenadas = fullfile(pwd, 'outputs_coordenadas_paralelas', 'dados_usados_coordenadas_paralelas.csv');

if isfile(arquivo_completo)
    arquivo_csv = arquivo_completo;
elseif isfile(arquivo_filtrado)
    arquivo_csv = arquivo_filtrado;
elseif isfile(arquivo_coordenadas)
    arquivo_csv = arquivo_coordenadas;
else
    error('Nenhum arquivo CSV encontrado. Verifique os caminhos das tabelas.');
end

disp('Arquivo usado:')
disp(arquivo_csv)

% ============================================================
% LENDO TABELA
% ============================================================
dados = readtable(arquivo_csv);

% Verifica colunas necessárias
colunas_necessarias = {'Kp','Ki','TempoSubida','Overshoot','Undershoot','ErroRampa'};

for i = 1:length(colunas_necessarias)
    if ~ismember(colunas_necessarias{i}, dados.Properties.VariableNames)
        error(['Coluna ausente na tabela: ' colunas_necessarias{i}]);
    end
end

% ============================================================
% LIMPEZA DOS DADOS
% ============================================================
% Remove linhas com NaN nos indicadores
dados = rmmissing(dados, 'DataVariables', colunas_necessarias);

% Se existirem colunas ValidoRegiao e Estavel, usa também
if ismember('ValidoRegiao', dados.Properties.VariableNames)
    dados = dados(dados.ValidoRegiao == 1, :);
end

if ismember('Estavel', dados.Properties.VariableNames)
    dados = dados(dados.Estavel == 1, :);
end

% ============================================================
% LIMITES-BASE DOS INDICADORES
% ============================================================
lim_TempoSubida = 10.0;
lim_Overshoot   = 0.25;
lim_Undershoot  = 0.15;
lim_ErroRampa   = 5.0;

% ============================================================
% NORMALIZAÇÃO PELOS LIMITES DE PROJETO
% ============================================================
dados.TempoSubida_norm = dados.TempoSubida / lim_TempoSubida;
dados.Overshoot_norm   = dados.Overshoot   / lim_Overshoot;
dados.Undershoot_norm  = dados.Undershoot  / lim_Undershoot;
dados.ErroRampa_norm   = dados.ErroRampa   / lim_ErroRampa;

% Matriz dos objetivos normalizados
F = dados{:, {'TempoSubida_norm','Overshoot_norm','Undershoot_norm','ErroRampa_norm'}};

% ============================================================
% CRITÉRIO DE KREISSELMEIER-STEINHÄUSER
% ============================================================
% rho controla o quanto o KS se aproxima do máximo.
% rho maior -> mais parecido com max(F_i)
% rho menor -> mais suavizado.
rho = 20;

% Forma numericamente estável:
m = max(F, [], 2);
KS = m + (1/rho) * log(sum(exp(rho * (F - m)), 2));

dados.KS = KS;

% Também salva o máximo simples dos indicadores normalizados
dados.MaxRatio = max(F, [], 2);

% Ordena da melhor para a pior solução
dados_KS = sortrows(dados, 'KS', 'ascend');

% ============================================================
% CLASSIFICAÇÃO PELOS CORTES PERCENTUAIS
% ============================================================
% Corte 0%  -> limites originais
% Corte 10% -> limites multiplicados por 0.90
% Corte 20% -> limites multiplicados por 0.80
% Corte 25% -> limites multiplicados por 0.75

dados_KS.Passa_0pct  = dados_KS.MaxRatio <= 1.00;
dados_KS.Passa_10pct = dados_KS.MaxRatio <= 0.90;
dados_KS.Passa_20pct = dados_KS.MaxRatio <= 0.80;
dados_KS.Passa_25pct = dados_KS.MaxRatio <= 0.75;

% ============================================================
% MOSTRANDO RESULTADOS
% ============================================================
disp('Top 20 soluções pelo critério KS:')
disp(dados_KS(1:min(20,height(dados_KS)), ...
    {'Kp','Ki','TempoSubida','Overshoot','Undershoot','ErroRampa','MaxRatio','KS', ...
     'Passa_0pct','Passa_10pct','Passa_20pct','Passa_25pct'}))

% ============================================================
% COMPARANDO COM OS PARES DO TRADE-OFF FINAL
% ============================================================
pares_final = [
    0.1 0.6;
    0.2 0.6;
    0.3 0.6
];

comparacao_final = table();

for i = 1:size(pares_final,1)

    Kp_ref = pares_final(i,1);
    Ki_ref = pares_final(i,2);

    idx = abs(dados_KS.Kp - Kp_ref) < 1e-9 & abs(dados_KS.Ki - Ki_ref) < 1e-9;

    if any(idx)
        linha = dados_KS(idx, :);
        linha.Rank_KS = find(idx);
        comparacao_final = [comparacao_final; linha];
    else
        warning('Par Kp=%.2f, Ki=%.2f não encontrado na tabela.', Kp_ref, Ki_ref);
    end
end

disp('Comparação dos pares escolhidos no trade-off final:')
disp(comparacao_final(:, ...
    {'Kp','Ki','TempoSubida','Overshoot','Undershoot','ErroRampa','MaxRatio','KS', ...
     'Passa_0pct','Passa_10pct','Passa_20pct','Passa_25pct'}))

% ============================================================
% SALVANDO CSVs
% ============================================================
writetable(dados_KS, fullfile(pasta_saida, 'tabela_com_KS_ordenada.csv'));
writetable(dados_KS(1:min(20,height(dados_KS)), :), fullfile(pasta_saida, 'top20_KS.csv'));
writetable(comparacao_final, fullfile(pasta_saida, 'comparacao_tradeoff_final_KS.csv'));

% ============================================================
% GRÁFICO 1 — TOP 20 PELO KS
% ============================================================
topN = min(20, height(dados_KS));
top = dados_KS(1:topN, :);

labels = strings(topN,1);

for i = 1:topN
    labels(i) = sprintf('Kp=%.2f, Ki=%.2f', top.Kp(i), top.Ki(i));
end

fig1 = figure('Position', [100 100 1200 650]);

bar(top.KS);
grid on;

xticks(1:topN);
xticklabels(labels);
xtickangle(45);

ylabel('Valor KS');
title('Top 20 Soluções pelo Critério Kreisselmeier-Steinhäuser');

exportgraphics(fig1, fullfile(pasta_saida, 'top20_KS.png'), 'Resolution', 300);
savefig(fig1, fullfile(pasta_saida, 'top20_KS.fig'));

% ============================================================
% GRÁFICO 2 — COMPARAÇÃO DOS 3 PARES FINAIS
% ============================================================
if ~isempty(comparacao_final)

    fig2 = figure('Position', [150 150 1000 600]);

    labels_final = strings(height(comparacao_final),1);

    for i = 1:height(comparacao_final)
        labels_final(i) = sprintf('Kp=%.2f, Ki=%.2f', comparacao_final.Kp(i), comparacao_final.Ki(i));
    end

    bar(comparacao_final.KS);
    grid on;

    xticks(1:height(comparacao_final));
    xticklabels(labels_final);
    xtickangle(0);

    ylabel('Valor KS');
    title('Critério KS para os Pares do Trade-off Final');

    exportgraphics(fig2, fullfile(pasta_saida, 'KS_pares_tradeoff_final.png'), 'Resolution', 300);
    savefig(fig2, fullfile(pasta_saida, 'KS_pares_tradeoff_final.fig'));

end

% ============================================================
% GRÁFICO 3 — INDICADORES NORMALIZADOS DOS 3 PARES FINAIS
% ============================================================
if ~isempty(comparacao_final)

    fig3 = figure('Position', [200 200 1100 650]);

    indicadores_norm_final = comparacao_final{:, ...
        {'TempoSubida_norm','Overshoot_norm','Undershoot_norm','ErroRampa_norm'}};

    bar(indicadores_norm_final);
    grid on;

    xticks(1:height(comparacao_final));
    xticklabels(labels_final);

    ylabel('Indicador normalizado pelo limite');
    title('Indicadores Normalizados dos Pares do Trade-off Final');

    legend({'TempoSubida/10','Overshoot/0.25','Undershoot/0.15','ErroRampa/5'}, ...
        'Location', 'bestoutside');

    exportgraphics(fig3, fullfile(pasta_saida, 'indicadores_normalizados_tradeoff_final.png'), 'Resolution', 300);
    savefig(fig3, fullfile(pasta_saida, 'indicadores_normalizados_tradeoff_final.fig'));

end

% ============================================================
% FINAL
% ============================================================
disp('Análise KS finalizada.')
disp('Arquivos salvos na pasta:')
disp(pasta_saida)