clc;
clear;
close all;

% ===============================
% PASTA DE SAÍDA
% ===============================
pasta_saida = fullfile(pwd, 'tradeoff_final_graficos');

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
% PARES (Kp, Ki) DO TRADE-OFF FINAL
% ===============================
pares = [
    0.1  0.6;
    0.2  0.6;
    0.3  0.6
];

% ===============================
% CORES FIXAS PARA OS PARES
% Cada linha = [R G B]
% ===============================
cores = [
    0.0000 0.4470 0.7410;   % azul
    0.8500 0.3250 0.0980;   % laranja
    0.9290 0.6940 0.1250    % amarelo
];

% Tempo de simulação
t = 0:0.01:20;

% ===============================
% GRÁFICO 1 - RESPOSTA AO DEGRAU
% ===============================
fig1 = figure('Position', [100 100 1000 600]);
hold on;
grid on;

for i = 1:size(pares,1)
    Kp = pares(i,1);
    Ki = pares(i,2);

    % Controlador PI: C(s) = (Kp*s + Ki)/s
    Controlador = tf([Kp Ki], [1 0]);

    % Malha fechada
    H = feedback(Sistema * Controlador, 1);

    % Resposta ao degrau
    [y_deg, t_deg] = step(H, t);

    plot(t_deg, y_deg, ...
        'LineWidth', 1.8, ...
        'Color', cores(i,:), ...
        'DisplayName', sprintf('Kp = %.1f, Ki = %.1f', Kp, Ki));
end

% Linha da referência
yline(1, '--k', 'Referência = 1', 'LineWidth', 1.2);

title('Resposta ao Degrau Unitário - Trade-off Final');
xlabel('Tempo [s]');
ylabel('Saída y(t)');
legend('Location', 'best');
hold off;

% Salvar gráfico
exportgraphics(fig1, fullfile(pasta_saida, 'resposta_degrau_tradeoff_final.png'), 'Resolution', 300);
savefig(fig1, fullfile(pasta_saida, 'resposta_degrau_tradeoff_final.fig'));

% ===============================
% GRÁFICO 2 - RESPOSTA À RAMPA
% ===============================
fig2 = figure('Position', [150 150 1000 600]);
hold on;
grid on;

% Referência rampa
rampa = t';
plot(t, rampa, '--k', 'LineWidth', 1.5, 'DisplayName', 'Referência r(t)');

for i = 1:size(pares,1)
    Kp = pares(i,1);
    Ki = pares(i,2);

    % Controlador PI
    Controlador = tf([Kp Ki], [1 0]);

    % Malha fechada
    H = feedback(Sistema * Controlador, 1);

    % Resposta à rampa
    y_rampa = lsim(H, rampa, t);

    plot(t, y_rampa, ...
        'LineWidth', 1.8, ...
        'Color', cores(i,:), ...
        'DisplayName', sprintf('Saída - Kp = %.1f, Ki = %.1f', Kp, Ki));
end

title('Resposta à Entrada de Rampa - Trade-off Final');
xlabel('Tempo [s]');
ylabel('Saída y(t)');
legend('Location', 'best');
hold off;

% Salvar gráfico
exportgraphics(fig2, fullfile(pasta_saida, 'resposta_rampa_tradeoff_final.png'), 'Resolution', 300);
savefig(fig2, fullfile(pasta_saida, 'resposta_rampa_tradeoff_final.fig'));

% ===============================
% MENSAGEM FINAL
% ===============================
disp('Gráficos gerados com sucesso.')
disp('Arquivos salvos na pasta:')
disp(pasta_saida)