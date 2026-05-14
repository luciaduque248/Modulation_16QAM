function [rxSymbols, I_mf_sync, Q_mf_sync, rxInfo] = demodulate_passband_16qam(y, p)
% DEMODULATE_PASSBAND_16QAM
% Demodulador coherente para 16-QAM pasabanda.
%
% Etapas:
%   1. Mezcla coherente con coseno y seno.
%   2. Filtro pasa bajas manual.
%   3. Filtro acoplado p(-t).
%   4. Compensación de retardo.
%   5. Muestreo en el instante óptimo.

    y = y(:);

    if ~isreal(y)
        error('La señal recibida debe ser real pasabanda.');
    end

    if p.M ~= 16
        error('Este demodulador está definido para 16-QAM.');
    end

    N = length(y);
    t = (0:N-1).' / p.Fs;

    % ============================================================
    % 1. Demodulación coherente I/Q
    % ============================================================

    carrierI = cos(2*pi*p.fc*t + p.phase);
    carrierQ = sin(2*pi*p.fc*t + p.phase);

    mixedI = sqrt(2) * y .* carrierI;
    mixedQ = -sqrt(2) * y .* carrierQ;

    % ============================================================
    % 2. Filtro pasa bajas
    % ============================================================

    lpf = local_lowpass_fir(p);
    lpf = lpf(:);

    bbI = conv(mixedI, lpf, 'full');
    bbQ = conv(mixedQ, lpf, 'full');

    % ============================================================
    % 3. Filtro acoplado
    % ============================================================

    pulse = local_rrc_pulse(p);
    pulse = pulse(:);

    matchedFilter = flipud(pulse);

    I_mf = conv(bbI, matchedFilter, 'full');
    Q_mf = conv(bbQ, matchedFilter, 'full');

    % ============================================================
    % 4. Compensación de retardos
    % ============================================================

    Lp = length(pulse);
    Llpf = length(lpf);

    delayTxPulse = (Lp - 1) / 2;
    delayLPF = (Llpf - 1) / 2;
    delayMatched = (Lp - 1) / 2;

    totalDelay = delayTxPulse + delayLPF + delayMatched;

    if abs(totalDelay - round(totalDelay)) > 1e-12
        error('El retardo total no es entero. Revise las longitudes de los filtros.');
    end

    totalDelay = round(totalDelay);

    NsymbolsExpected = p.Nbits / p.k;

    firstSample = totalDelay + 1;
    lastSample = firstSample + (NsymbolsExpected - 1)*p.sps;

    if lastSample > length(I_mf)
        error('No hay suficientes muestras para recuperar todos los símbolos.');
    end

    sampleIndex = firstSample:p.sps:lastSample;

    rxI = I_mf(sampleIndex);
    rxQ = Q_mf(sampleIndex);

    rxSymbols = rxI + 1j*rxQ;

    % ============================================================
    % 5. Corrección de ganancia residual
    % ============================================================

    rxEnergy = mean(abs(rxSymbols).^2);

    if rxEnergy <= 0
        error('La energía recibida es inválida.');
    end

    gainCorrection = sqrt(p.Es / rxEnergy);

    rxSymbols = rxSymbols * gainCorrection;
    I_mf = I_mf * gainCorrection;
    Q_mf = Q_mf * gainCorrection;

    % ============================================================
    % 6. Señales sincronizadas para diagrama de ojo
    % ============================================================

    syncStart = firstSample;
    syncEnd = min(length(I_mf), firstSample + (NsymbolsExpected*p.sps) - 1);

    I_mf_sync = I_mf(syncStart:syncEnd);
    Q_mf_sync = Q_mf(syncStart:syncEnd);

    % ============================================================
    % Información de depuración
    % ============================================================

    rxInfo.mixedI = mixedI;
    rxInfo.mixedQ = mixedQ;
    rxInfo.lpf = lpf;
    rxInfo.bbI = bbI;
    rxInfo.bbQ = bbQ;
    rxInfo.pulse = pulse;
    rxInfo.matchedFilter = matchedFilter;
    rxInfo.I_mf = I_mf;
    rxInfo.Q_mf = Q_mf;
    rxInfo.totalDelay = totalDelay;
    rxInfo.firstSample = firstSample;
    rxInfo.lastSample = lastSample;
    rxInfo.sampleIndex = sampleIndex;
    rxInfo.NsymbolsRecovered = length(rxSymbols);
    rxInfo.rxEnergyBeforeGainCorrection = rxEnergy;
    rxInfo.gainCorrection = gainCorrection;
end


function pulse = local_rrc_pulse(p)
% LOCAL_RRC_PULSE
% Pulso raíz de coseno alzado diseñado según la teoría:
%
%   g(t) = p(t) * p(-t)
%
% En frecuencia:
%
%   |P(f)| = sqrt(G(f))
%
% donde G(f) es el espectro de coseno alzado.
%
% No usa rcosdesign.

    alpha = p.alpha;
    sps = p.sps;
    span = p.pulseSpanSymbols;

    if alpha < 0 || alpha > 1
        error('El factor de roll-off alpha debe estar entre 0 y 1.');
    end

    if mod(span, 2) ~= 0
        error('pulseSpanSymbols debe ser par para obtener un pulso simétrico.');
    end

    L = span*sps + 1;

    Nfft = 2^nextpow2(max(4096, 16*L));

    Fs_norm = sps;
    f = (-Nfft/2:Nfft/2-1).' * (Fs_norm/Nfft);

    absf = abs(f);

    G = zeros(Nfft, 1);

    if alpha == 0

        G(absf <= 0.5) = 1;

    else

        f1 = (1 - alpha)/2;
        f2 = (1 + alpha)/2;

        idxFlat = absf <= f1;
        G(idxFlat) = 1;

        idxRoll = (absf > f1) & (absf <= f2);

        G(idxRoll) = 0.5 * ...
            (1 + cos((pi/alpha) * (absf(idxRoll) - f1)));
    end

    P = sqrt(G);

    pulseLong = real(ifft(ifftshift(P)));

    pulseLong = fftshift(pulseLong);

    centerIndex = floor(Nfft/2) + 1;
    startIndex = centerIndex - floor(L/2);
    endIndex = startIndex + L - 1;

    pulse = pulseLong(startIndex:endIndex);

    pulse = pulse(:);

    pulseEnergy = sum(abs(pulse).^2);

    if pulseEnergy <= 0
        error('La energía del pulso es inválida.');
    end

    pulse = pulse / sqrt(pulseEnergy);
end


function h = local_lowpass_fir(p)
% LOCAL_LOWPASS_FIR
% Filtro pasa bajas FIR manual.
%
% Se usa después de mezclar la señal pasabanda con seno y coseno.
% Su función es conservar la componente de banda base y atenuar las
% componentes alrededor de 2fc.
%
% No usa fir1 ni funciones automáticas equivalentes.

    filterSpanSymbols = 8;
    L = filterSpanSymbols * p.sps + 1;

    if mod(L, 2) == 0
        L = L + 1;
    end

    n = (0:L-1).';
    m = n - (L-1)/2;

    cutoffHz = min(2.5 * p.BW_baseband, 0.45 * p.Fs);

    fcNorm = cutoffHz / p.Fs;

    h = zeros(L, 1);

    for k = 1:L
        if m(k) == 0
            h(k) = 2 * fcNorm;
        else
            h(k) = sin(2*pi*fcNorm*m(k)) / (pi*m(k));
        end
    end

    window = 0.54 - 0.46*cos(2*pi*n/(L-1));

    h = h .* window;

    h = h / sum(h);
end