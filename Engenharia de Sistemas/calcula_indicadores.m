%calcula_indicadores.m

function indicadores = calcula_indicadores(Kp, Ki)

% Sistema do enunciado
A = [-3 -2; 1 0];
B = [1; 0];
C = [-1 1];
D = 0;

Sistema = ss(A,B,C,D);

% Verificação da região admissível
Ki_max = ((Kp-3)*(Kp+2))/(Kp-4);

if Kp <= -2 || Kp >= 3
    warning('Kp está fora da faixa permitida: -2 < Kp < 3');
end

if Ki <= 0 || Ki >= Ki_max
    warning('Ki está fora da faixa permitida: 0 < Ki < Ki_max');
end

% Controlador PI
% C(s) = Kp + Ki/s = (Kp*s + Ki)/s
Controlador = tf([Kp Ki],[1 0]);

% Malha fechada
H = feedback(Sistema*Controlador,1);

% Tempo de simulação
t = 0:0.01:20;

% Resposta ao degrau
[y_degrau,t_degrau] = step(H,t);

% 1. Tempo de subida
idx = find(y_degrau > 0.9,1);

if isempty(idx)
    TempoSubida = NaN;
else
    TempoSubida = t_degrau(idx);
end

% 2. Overshoot
Overshoot = max(0,max(y_degrau)-1);

% 3. Undershoot
Undershoot = max(0,-min(y_degrau));

% Resposta à rampa
rampa = t';
y_rampa = lsim(H,rampa,t);

% 4. Erro de rampa no final da simulação
ErroRampa = abs(rampa(end) - y_rampa(end));

% Criando tabela de saída
indicadores = table(Kp, Ki, Ki_max, TempoSubida, Overshoot, Undershoot, ErroRampa);

end