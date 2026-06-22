function [valores] = var_analise(k)
    A=[-3 -2;1 0];B=[1;0];C=[-1 1]; D=0; Sistema=ss(A,B,C,D);
    a=0;b=1;c=k(2);d=k(1); % k(1) e' Kp, k(2) e' Ki
    Controlador=ss(a,b,c,d);
    %
    % sistema e controlador em malha de realimentação unitária
    %
    H=feedback(Sistema*Controlador,1);
    y = step(H,0:.01:19.99);
    [dummy,index]=max(y>0.9);
    ts=(index-1)*.01; % tempo de subida
    % Se em 20 segundos o sinal não atingir
    % 90% da referênci,a ts é estimado por extrapolacao linear do sinal
    if ts==0
     ts=18/max(y);
    end
    Mp=(max(y)-1); % overshoot
    Und=abs(min(y)); % undershoot
    Erampa=2/k(2); % erro de regime para entrada rampa unitária
    valores=[ts;Mp;Und;Erampa];
end