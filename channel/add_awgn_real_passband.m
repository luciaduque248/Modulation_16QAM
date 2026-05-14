function [y, noiseInfo] = add_awgn_real_passband(x, p, EbN0_dB)
% ADD_AWGN_REAL_PASSBAND
% Canal AWGN para señal pasabanda real.
%
% Se usa:
%   Es = energía promedio de símbolo
%   Eb = Es/log2(M)
%   N0 = Eb/(Eb/N0)
%   varianza por dimensión = N0/2
%
% En esta simulación discreta, el ruido se ajusta para que después de
% demodulación coherente y filtro acoplado la varianza por rama sea N0/2.

    x = x(:);

    if ~isreal(x)
        error('La señal de entrada al canal debe ser real pasabanda.');
    end

    if p.M ~= 16
        error('El sistema está configurado para 16-QAM. p.M debe ser 16.');
    end

    EbN0_linear = 10^(EbN0_dB/10);

    Es = p.Es;
    Eb = Es / p.k;
    N0 = Eb / EbN0_linear;

    % Varianza discreta del ruido pasabanda.
    % No se multiplica por Fs porque la cadena de simulación está normalizada
    % por energía discreta de pulso.
    sigma2 = N0 / 2;

    noise = sqrt(sigma2) * randn(size(x));

    y = x + noise;

    noiseInfo.EbN0_dB = EbN0_dB;
    noiseInfo.EbN0_linear = EbN0_linear;
    noiseInfo.Es = Es;
    noiseInfo.Eb = Eb;
    noiseInfo.N0 = N0;
    noiseInfo.sigma2 = sigma2;
    noiseInfo.sigma = sqrt(sigma2);
end