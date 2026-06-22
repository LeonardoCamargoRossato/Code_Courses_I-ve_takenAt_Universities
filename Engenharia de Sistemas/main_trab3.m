clc;
clear;
close all;

% Pasta onde os outputs serão salvos
pasta_saida = fullfile(pwd, 'outputs_PI');

if ~exist(pasta_saida, 'dir')
    mkdir(pasta_saida);
end

% Sistema do enunciado
A = [-3 -2; 1 0];
B = [1; 0];
C = [-1 1];
D = 0;

Sistema = ss(A,B,C,D);

% Vetor de ganhos Kp dentro da região permitida
Kp_vec = linspace(-1.9,2.9,80);

% Matriz para armazenar os resultados
resultados = [];

% Varredura dos pares Kp e Ki
for i = 1:length(Kp_vec)

    Kp = Kp_vec(i);

    Ki_max = ((Kp-3)*(Kp+2))/(Kp-4);

    if Ki_max <= 0
        continue;
    end

    Ki_vec = linspace(0.01,0.98*Ki_max,80);

    for j = 1:length(Ki_vec)

        Ki = Ki_vec(j);

        valores = var_analise([Kp Ki]);

        ts = valores(1);
        Mp = valores(2);
        Und = valores(3);
        Erro_rampa = valores(4);

        resultados = [resultados; Kp Ki ts Mp Und Erro_rampa];

    end
end

% Convertendo resultados para tabela
if isempty(resultados)
    error('Nenhum par Kp, Ki válido foi encontrado. Verifique a fórmula de Ki_max e a região de busca.');
end

dados = array2table(resultados, ...
    'VariableNames', {'Kp','Ki','TempoSubida','Overshoot','Undershoot','ErroRampa'});

disp('Primeiras 10 soluções testadas:')
disp(dados(1:10,:))

% Métricas agregadas
objetivos = dados{:,{'TempoSubida','Overshoot','Undershoot','ErroRampa'}};

min_obj = min(objetivos);
max_obj = max(objetivos);

objetivos_norm = (objetivos - min_obj)./(max_obj - min_obj);

rho = 20;

m = max(objetivos_norm,[],2);

KS = m + log(sum(exp(rho*(objetivos_norm - m)),2))/rho;

dados.KS = KS;

% Quanto menor o KS, melhor o equilíbrio entre os 4 objetivos
dados = sortrows(dados,'KS','ascend');

melhor = dados(1,:);

disp('Melhor solução encontrada:')
disp(melhor)

Kp_best = melhor.Kp;
Ki_best = melhor.Ki;

% Sistema em malha fechada com melhor controlador
Controlador_best = tf([Kp_best Ki_best],[1 0]);
H_best = feedback(Sistema*Controlador_best,1);

t = 0:0.01:20;

% Gráfico 1: resposta ao degrau
fig1 = figure('Position',[100 100 900 500]);

step(H_best,t);
grid on;
title('Resposta ao Degrau Unitário - Melhor Controlador PI');
xlabel('Tempo [s]');
ylabel('Saída y(t)');

% Salvando gráfico do degrau
exportgraphics(fig1, fullfile(pasta_saida, 'resposta_degrau_PI.png'), 'Resolution', 300);
savefig(fig1, fullfile(pasta_saida, 'resposta_degrau_PI.fig'));

% Gráfico 2: resposta à rampa
fig2 = figure('Position',[150 150 900 500]);

rampa = t';
y_rampa = lsim(H_best,rampa,t);

plot(t,rampa,'--','LineWidth',1.5);
hold on;
plot(t,y_rampa,'LineWidth',1.5);
grid on;
title('Resposta à Entrada Rampa Unitária');
xlabel('Tempo [s]');
ylabel('Saída y(t)');
legend('Referência r(t)','Saída y(t)','Location','best');

% Salvando gráfico da rampa
exportgraphics(fig2, fullfile(pasta_saida, 'resposta_rampa_PI.png'), 'Resolution', 300);
savefig(fig2, fullfile(pasta_saida, 'resposta_rampa_PI.fig'));

% Gráfico 3: mapa dos pares testados
fig3 = figure('Position',[200 200 900 500]);

scatter(dados.Kp,dados.Ki,40,dados.KS,'filled');
colorbar;
grid on;
xlabel('Kp');
ylabel('Ki');
title('Mapa de Soluções PI - Cor indica valor da função KS');

% Salvando mapa de soluções
exportgraphics(fig3, fullfile(pasta_saida, 'mapa_solucoes_Kp_Ki.png'), 'Resolution', 300);
savefig(fig3, fullfile(pasta_saida, 'mapa_solucoes_Kp_Ki.fig'));

% Salvando tabela completa
writetable(dados, fullfile(pasta_saida, 'resultados_completos_PI.csv'));

% Salvando as 10 melhores soluções
writetable(dados(1:10,:), fullfile(pasta_saida, 'melhores_10_solucoes_PI.csv'));

% Salvando melhor solução separadamente
writetable(melhor, fullfile(pasta_saida, 'melhor_solucao_PI.csv'));

% Salvando variáveis principais do Workspace
save(fullfile(pasta_saida, 'resultados_workspace_PI.mat'), ...
    'dados', 'melhor', 'Kp_best', 'Ki_best', 'H_best', 'Sistema', 'Controlador_best');

% Mensagem final
disp('Processamento finalizado.')
disp('Todos os outputs foram salvos na pasta:')
disp(pasta_saida)