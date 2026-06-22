%gerar_tabela_por_Ki.m

function tabela_resultado = gerar_tabela_por_Ki(Ki)

clc;
close all;

% ===============================
% INPUT DO USUÁRIO
% ===============================
% Ki é escolhido pelo usuário na chamada da função.
% Exemplo:
% gerar_tabela_por_Ki(0.1)

% ===============================
% PASTA DE SAÍDA
% ===============================
Ki_txt = strrep(num2str(Ki, '%.4f'), '.', 'p');
pasta_saida = fullfile(pwd, ['tabela_result_ki_' Ki_txt]);

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
% VETOR DE Kp
% ===============================
Kp_vec = -2:0.4:3;

% Garante que o valor 3 entre na tabela
if Kp_vec(end) < 3
    Kp_vec = [Kp_vec 3];
end

% ===============================
% MATRIZ DE RESULTADOS
% Colunas:
% Kp, Ki, Ki_max, TempoSubida, Overshoot, Undershoot, ErroRampa
% ===============================
resultados = [];

for i = 1:length(Kp_vec)

    Kp = Kp_vec(i);

    % Cálculo do Ki máximo
    Ki_max = ((Kp - 3)*(Kp + 2))/(Kp - 4);

    % Calcula os indicadores
    [TempoSubida, Overshoot, Undershoot, ErroRampa] = calcula_indicadores_local(Kp, Ki, Sistema);

    % Salva uma linha na matriz
    resultados = [resultados; Kp Ki Ki_max TempoSubida Overshoot Undershoot ErroRampa];

end

% ===============================
% CONVERTENDO PARA TABELA
% ===============================
tabela_resultado = array2table(resultados, ...
    'VariableNames', {'Kp','Ki','Ki_max','TempoSubida','Overshoot','Undershoot','ErroRampa'});

% Mostra a tabela no Command Window
disp(tabela_resultado)

% ===============================
% SALVANDO TABELA
% ===============================
arquivo_csv = fullfile(pasta_saida, ['tabela_result_ki_' Ki_txt '.csv']);
arquivo_mat = fullfile(pasta_saida, ['tabela_result_ki_' Ki_txt '.mat']);

writetable(tabela_resultado, arquivo_csv);
save(arquivo_mat, 'tabela_resultado');

% ===============================
% GRÁFICO DOS 5 INDICADORES EM FUNÇÃO DE Kp
% ===============================
fig = figure('Position', [100 100 1000 600]);

plot(tabela_resultado.Kp, tabela_resultado.Ki_max, '-o', 'LineWidth', 1.5);
hold on;

plot(tabela_resultado.Kp, tabela_resultado.TempoSubida, '-o', 'LineWidth', 1.5);
plot(tabela_resultado.Kp, tabela_resultado.Overshoot, '-o', 'LineWidth', 1.5);
plot(tabela_resultado.Kp, tabela_resultado.Undershoot, '-o', 'LineWidth', 1.5);
plot(tabela_resultado.Kp, tabela_resultado.ErroRampa, '-o', 'LineWidth', 1.5);

grid on;

title(['Indicadores em função de Kp para Ki = ' num2str(Ki)]);
xlabel('Kp');
ylabel('Valor dos indicadores');

legend( ...
    'Ki_{max}', ...
    'TempoSubida', ...
    'Overshoot', ...
    'Undershoot', ...
    'ErroRampa', ...
    'Location', 'best' ...
);

% ===============================
% SALVANDO GRÁFICO
% ===============================
arquivo_png = fullfile(pasta_saida, ['grafico_indicadores_ki_' Ki_txt '.png']);
arquivo_fig = fullfile(pasta_saida, ['grafico_indicadores_ki_' Ki_txt '.fig']);

exportgraphics(fig, arquivo_png, 'Resolution', 300);
savefig(fig, arquivo_fig);

% ===============================
% MENSAGEM FINAL
% ===============================
disp('Arquivos salvos na pasta:')
disp(pasta_saida)

end


% =====================================================
% FUNÇÃO LOCAL PARA CALCULAR OS INDICADORES
% =====================================================
function [TempoSubida, Overshoot, Undershoot, ErroRampa] = calcula_indicadores_local(Kp, Ki, Sistema)

% Valores padrão caso a simulação falhe
TempoSubida = NaN;
Overshoot = NaN;
Undershoot = NaN;
ErroRampa = NaN;

try

    % Controlador PI
    % C(s) = Kp + Ki/s = (Kp*s + Ki)/s
    Controlador = tf([Kp Ki], [1 0]);

    % Malha fechada
    H = feedback(Sistema*Controlador, 1);

    % Se o sistema for instável, mantém NaN
    if ~isstable(H)
        return;
    end

    % Tempo de simulação
    t = 0:0.01:20;

    % Resposta ao degrau
    [y_degrau, t_degrau] = step(H, t);

    % Tempo de subida: primeiro instante em que y(t) passa de 90% da referência
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

    % Resposta à rampa
    rampa = t';
    y_rampa = lsim(H, rampa, t);

    % Erro final da rampa
    ErroRampa = abs(rampa(end) - y_rampa(end));

catch

    % Se der erro numérico, mantém NaN
    TempoSubida = NaN;
    Overshoot = NaN;
    Undershoot = NaN;
    ErroRampa = NaN;

end

end