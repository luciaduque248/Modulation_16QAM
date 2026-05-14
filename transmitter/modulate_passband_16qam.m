function [xPassband, txInfo] = modulate_passband_16qam(symbols, p)
% MODULATE_PASSBAND_16QAM
% Modulador 16-QAM pasabanda real.
%
% Entrada:
%   symbols = símbolos complejos 16-QAM normalizados con Es = 1
%
% Etapas:
%   1. Separación I/Q.
%   2. Sobremuestreo.
%   3. Conformación de pulso con raíz de coseno alzado.
%   4. Modulación pasabanda real.
%
% Modelo:
%   s(t) = sI(t) + j sQ(t)
%   x_c(t) = sqrt(2)*sI(t)*cos(2*pi*fc*t)
%            - sqrt(2)*sQ(t)*sin(2*pi*fc*t)

    symbols = symbols(:);

    if p.M ~= 16
        error('Este modulador está definido para 16-QAM.');
    end

    if isempty(symbols)
        error('La secuencia de símbolos no puede estar vacía.');
    end

    symbolsI = real(symbols);
    symbolsQ = imag(symbols);

    pulse = local_rrc_pulse(p);
    pulse = pulse(:);

    upI = zeros(length(symbolsI) * p.sps, 1);
    upQ = zeros(length(symbolsQ) * p.sps, 1);

    upI(1:p.sps:end) = symbolsI;
    upQ(1:p.sps:end) = symbolsQ;

    sI = conv(upI, pulse, 'full');
    sQ = conv(upQ, pulse, 'full');

    N = length(sI);
    t = (0:N-1).' / p.Fs;

    carrierI = cos(2*pi*p.fc*t + p.phase);
    carrierQ = sin(2*pi*p.fc*t + p.phase);

    xPassband = sqrt(2) * sI .* carrierI - sqrt(2) * sQ .* carrierQ;

    txInfo.symbolsI = symbolsI;
    txInfo.symbolsQ = symbolsQ;
    txInfo.upI = upI;
    txInfo.upQ = upQ;
    txInfo.sI = sI;
    txInfo.sQ = sQ;
    txInfo.pulse = pulse;
    txInfo.t = t;
    txInfo.Nsymbols = length(symbols);
    txInfo.pulseEnergyDiscrete = sum(abs(pulse).^2);
end


function pulse = local_rrc_pulse(p)
% LOCAL_RRC_PULSE
% Pulso raíz de coseno alzado.
%
% La teoría define:
%
%   g(t) = p(t) * p(-t)
%
% donde g(t) es el filtro de coseno alzado.
%
% En frecuencia:
%
%   |P(f)|^2 = sqrt(G(f))
%
% Por tanto, esta función:
%   1. Construye G(f), espectro de coseno alzado.
%   2. Calcula P(f) = sqrt(G(f)).
%   3. Obtiene p(t) mediante IFFT.
%   4. Recorta el pulso a una duración finita.
%   5. Normaliza la energía discreta del pulso a 1.

    alpha = p.alpha;
    sps = p.sps;
    span = p.pulseSpanSymbols;

    if alpha < 0 || alpha > 1
        error('El factor de roll-off alpha debe estar entre 0 y 1.');
    end

    if mod(span, 2) ~= 0
        error('pulseSpanSymbols debe ser par para obtener un pulso simétrico.');
    end

    % Longitud final del pulso en muestras.
    L = span*sps + 1;

    % Se usa una FFT grande para aproximar bien el paso frecuencia-tiempo.
    Nfft = 2^nextpow2(max(4096, 16*L));

    % Eje de frecuencia normalizado en ciclos por símbolo.
    % Como el tiempo está normalizado por T, se toma T = 1.
    Fs_norm = sps;
    f = (-Nfft/2:Nfft/2-1).' * (Fs_norm/Nfft);

    absf = abs(f);

    % ============================================================
    % Espectro de coseno alzado G(f)
    %
    % Según la teoría:
    %
    % G(f) = 1,
    %        |f| <= (1-alpha)/(2T)
    %
    % G(f) = 1/2 [1 + cos( pi*T/alpha *
    %        ( |f| - (1-alpha)/(2T) ) )],
    %        (1-alpha)/(2T) < |f| <= (1+alpha)/(2T)
    %
    % G(f) = 0,
    %        en otro caso
    %
    % Como se trabaja en tiempo normalizado:
    % T = 1
    % ============================================================

    G = zeros(Nfft, 1);

    if alpha == 0

        % Caso ideal alpha = 0:
        % ancho hasta 1/(2T), con T = 1.
        G(absf <= 0.5) = 1;

    else

        f1 = (1 - alpha)/2;
        f2 = (1 + alpha)/2;

        % Banda plana
        idxFlat = absf <= f1;
        G(idxFlat) = 1;

        % Banda de transición
        idxRoll = (absf > f1) & (absf <= f2);

        G(idxRoll) = 0.5 * ...
            (1 + cos((pi/alpha) * (absf(idxRoll) - f1)));

        % Fuera de banda queda en cero
    end

    % ============================================================
    % Raíz cuadrada del espectro:
    %
    % |P(f)|^2 = sqrt(G(f))
    %
    % Esto es lo que convierte el coseno alzado en raíz de coseno
    % alzado.
    % ============================================================

    P = sqrt(G);

    % Pasar de frecuencia a tiempo.
    % P está centrado con frecuencias negativas y positivas,
    % por eso se usa ifftshift antes de ifft.
    pulseLong = real(ifft(ifftshift(P)));

    % Centrar el pulso en t = 0.
    pulseLong = fftshift(pulseLong);

    % Recortar una ventana finita de duración span símbolos.
    centerIndex = floor(Nfft/2) + 1;
    startIndex = centerIndex - floor(L/2);
    endIndex = startIndex + L - 1;

    pulse = pulseLong(startIndex:endIndex);

    % Asegurar vector columna
    pulse = pulse(:);

    % Normalización de energía discreta:
    %
    % sum |p[n]|^2 = 1
    %
    % Esto mantiene coherente Es, Eb, N0 y la BER.
    pulseEnergy = sum(abs(pulse).^2);

    if pulseEnergy <= 0
        error('La energía del pulso es inválida.');
    end

    pulse = pulse / sqrt(pulseEnergy);
end