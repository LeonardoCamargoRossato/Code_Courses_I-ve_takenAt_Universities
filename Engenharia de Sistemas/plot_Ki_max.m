%plot_Ki_max.m

clc;
clear;
close all;

% Vetor de Kp
Kp_vec = linspace(-1.9, 2.9, 80);

% Cálculo de Ki máximo para cada Kp
Ki_max = ((Kp_vec - 3).*(Kp_vec + 2))./(Kp_vec - 4);

% Criando pasta de saída
pasta_saida = fullfile(pwd, 'outputs_Ki_max');

if ~exist(pasta_saida, 'dir')
    mkdir(pasta_saida);
end

% Criando gráfico
fig = figure('Position', [100 100 900 500]);

plot(Kp_vec, Ki_max, 'LineWidth', 2);
grid on;

title('Limite Superior de Ki em Função de Kp');
xlabel('Kp');
ylabel('Ki_{max}');

% Destacando região válida
hold on;
yline(0, '--', 'Ki = 0');

% Salvando gráfico em PNG e FIG
exportgraphics(fig, fullfile(pasta_saida, 'Ki_max_em_funcao_de_Kp.png'), 'Resolution', 300);
savefig(fig, fullfile(pasta_saida, 'Ki_max_em_funcao_de_Kp.fig'));

% Salvando os dados em CSV também
tabela_Ki = table(Kp_vec', Ki_max', ...
    'VariableNames', {'Kp', 'Ki_max'});

writetable(tabela_Ki, fullfile(pasta_saida, 'dados_Ki_max.csv'));

disp('Gráfico e dados salvos na pasta:')
disp(pasta_saida)