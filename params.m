function p = params()
% PARAMS
% Define los parámetros del sistema 16-QAM sobre canal AWGN
% y muestra en consola las fórmulas principales con sus resultados.

    % ============================================================
    % Modulación
    % ============================================================

    p.M = 16;
    p.k = log2(p.M);

    if p.k ~= round(p.k)
        error('M debe ser potencia de 2.');
    end

    % 16-QAM cuadrada: 4 niveles en fase y 4 niveles en cuadratura
    p.sqrtM = sqrt(p.M);

    if p.sqrtM ~= round(p.sqrtM)
        error('Para 16-QAM cuadrada, sqrt(M) debe ser entero.');
    end

    % Niveles 4-PAM por dimensión antes de normalizar
    p.unscaledLevels = [-3; -1; 1; 3];

    % Energía promedio por dimensión sin normalizar:
    % E[I^2] = ((-3)^2 + (-1)^2 + (1)^2 + (3)^2)/4 = 5
    p.EI2_unscaled = mean(p.unscaledLevels.^2);

    % Energía promedio de símbolo sin normalizar:
    % Es_unscaled = E[I^2] + E[Q^2] = 5 + 5 = 10
    p.EsUnscaled = 2 * p.EI2_unscaled;

    % Normalización:
    % s_norm = s / sqrt(Es_unscaled)
    % Para 16-QAM con niveles {-3,-1,1,3}: escala = 1/sqrt(10)
    p.constellationScale = 1 / sqrt(p.EsUnscaled);

    % Energías normalizadas:
    % Es = 1
    % Eb = Es / log2(M)
    p.Es = 1;
    p.Eb = p.Es / p.k;

    % ============================================================
    % Tamaño de simulación y Eb/N0
    % ============================================================

    p.Nbits = 400000;
    p.Nsymbols = p.Nbits / p.k;

    if p.Nsymbols ~= round(p.Nsymbols)
        error('El número de bits debe ser múltiplo de log2(M).');
    end

    p.EbN0_dB = 0:2:20;

    % Eb/N0 usado para constelación y ojo
    p.EbN0_eye_dB = 20;

    % ============================================================
    % Tasas temporales
    % ============================================================

    p.Rb = 4000;

    % Rs = Rb / log2(M)
    p.Rs = p.Rb / p.k;

    % Ts = 1 / Rs
    p.Ts = 1 / p.Rs;

    % Muestras por símbolo
    p.sps = 16;

    % Fs = sps * Rs
    p.Fs = p.sps * p.Rs;

    % dt = 1 / Fs
    p.dt = 1 / p.Fs;

    % Portadora
    % fc = 4 * Rs
    p.fc = 4 * p.Rs;
    p.phase = 0;

    if p.fc >= p.Fs/2
        error('fc debe ser menor que Fs/2.');
    end

    % ============================================================
    % Pulso conformador
    % ============================================================

    % Factor de roll-off del pulso de raíz de coseno alzado
    p.alpha = 0.75;

    if p.alpha < 0 || p.alpha > 1
        error('El factor de roll-off alpha debe estar entre 0 y 1.');
    end

    % Duración del pulso en símbolos para implementación discreta manual
    p.pulseSpanSymbols = 16;

    if mod(p.pulseSpanSymbols, 2) ~= 0
        error('pulseSpanSymbols debe ser par.');
    end

    % Tipo de pulso
    p.pulseType = 'manual_rrc';

    % Cantidad aproximada de muestras del pulso
    p.pulseLengthSamples = p.pulseSpanSymbols * p.sps + 1;

    % ============================================================
    % Ancho de banda teórico
    %
    % Banda base:
    % B = Rb(1 + alpha) / (2 log2(M))
    %
    % Pasabanda:
    % W = Rb(1 + alpha) / log2(M)
    % ============================================================

    p.BW_baseband = p.Rb * (1 + p.alpha) / (2 * p.k);
    p.BW_passband = p.Rb * (1 + p.alpha) / p.k;

    % Banda positiva aproximada alrededor de +fc
    p.fBandPositiveMin = p.fc - p.BW_passband/2;
    p.fBandPositiveMax = p.fc + p.BW_passband/2;

    % Banda negativa aproximada alrededor de -fc
    p.fBandNegativeMin = -p.fc - p.BW_passband/2;
    p.fBandNegativeMax = -p.fc + p.BW_passband/2;

    % ============================================================
    % Visualización
    % ============================================================

    p.eyeTraces = 140;
    p.constellationPointsToShow = 5000;

    % ============================================================
    % Reproducibilidad
    % ============================================================

    p.rngSeed = 12345;

    % ============================================================
    % Mostrar resumen en consola
    % ============================================================

    print_params_report(p);

end


function print_params_report(p)
% PRINT_PARAMS_REPORT
% Muestra en consola las fórmulas principales y sus resultados.

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf(' RESUMEN DE PARAMETROS DEL SISTEMA 16-QAM SOBRE AWGN\n');
    fprintf('============================================================\n\n');

    fprintf('1) MODULACION\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Formula: k = log2(M)\n');
    fprintf('Sustitucion: k = log2(%d)\n', p.M);
    fprintf('Resultado: k = %.0f bits/simbolo\n\n', p.k);

    fprintf('Formula: sqrt(M)\n');
    fprintf('Sustitucion: sqrtM = sqrt(%d)\n', p.M);
    fprintf('Resultado: sqrtM = %.0f niveles por dimension\n\n', p.sqrtM);

    fprintf('Interpretacion:\n');
    fprintf('16-QAM cuadrada = 4-PAM en fase x 4-PAM en cuadratura\n');
    fprintf('Total de simbolos = %.0f x %.0f = %.0f simbolos\n\n', ...
        p.sqrtM, p.sqrtM, p.sqrtM*p.sqrtM);

    fprintf('Niveles 4-PAM sin normalizar por dimension:\n');
    fprintf('{ -3, -1, 1, 3 }\n\n');

    fprintf('2) NORMALIZACION DE CONSTELACION\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Formula: E[I^2] = ((-3)^2 + (-1)^2 + (1)^2 + (3)^2)/4\n');
    fprintf('Resultado: E[I^2] = %.4f\n\n', p.EI2_unscaled);

    fprintf('Formula: Es_sin_normalizar = E[I^2] + E[Q^2]\n');
    fprintf('Sustitucion: Es_sin_normalizar = %.4f + %.4f\n', ...
        p.EI2_unscaled, p.EI2_unscaled);
    fprintf('Resultado: Es_sin_normalizar = %.4f\n\n', p.EsUnscaled);

    fprintf('Formula: escala = 1/sqrt(Es_sin_normalizar)\n');
    fprintf('Sustitucion: escala = 1/sqrt(%.4f)\n', p.EsUnscaled);
    fprintf('Resultado: escala = %.8f\n\n', p.constellationScale);

    fprintf('Formula: Es = 1 despues de normalizar\n');
    fprintf('Resultado: Es = %.4f\n\n', p.Es);

    fprintf('Formula: Eb = Es/log2(M)\n');
    fprintf('Sustitucion: Eb = %.4f / %.0f\n', p.Es, p.k);
    fprintf('Resultado: Eb = %.4f\n\n', p.Eb);

    fprintf('3) TAMANO DE SIMULACION\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Bits transmitidos: Nbits = %d\n', p.Nbits);
    fprintf('Formula: Nsimbolos = Nbits / k\n');
    fprintf('Sustitucion: Nsimbolos = %d / %.0f\n', p.Nbits, p.k);
    fprintf('Resultado: Nsimbolos = %.0f\n\n', p.Nsymbols);

    fprintf('Barrido Eb/N0 [dB]: ');
    fprintf('%.0f ', p.EbN0_dB);
    fprintf('\n\n');

    fprintf('Eb/N0 usado para ojo y constelacion: %.1f dB\n\n', ...
        p.EbN0_eye_dB);

    fprintf('4) TASAS TEMPORALES\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Tasa de bits: Rb = %.2f bit/s\n\n', p.Rb);

    fprintf('Formula: Rs = Rb/log2(M)\n');
    fprintf('Sustitucion: Rs = %.2f / %.0f\n', p.Rb, p.k);
    fprintf('Resultado: Rs = %.2f simbolos/s\n\n', p.Rs);

    fprintf('Formula: Ts = 1/Rs\n');
    fprintf('Sustitucion: Ts = 1 / %.2f\n', p.Rs);
    fprintf('Resultado: Ts = %.8f s\n\n', p.Ts);

    fprintf('Muestras por simbolo: sps = %.0f\n\n', p.sps);

    fprintf('Formula: Fs = sps * Rs\n');
    fprintf('Sustitucion: Fs = %.0f * %.2f\n', p.sps, p.Rs);
    fprintf('Resultado: Fs = %.2f Hz\n\n', p.Fs);

    fprintf('Formula: dt = 1/Fs\n');
    fprintf('Sustitucion: dt = 1 / %.2f\n', p.Fs);
    fprintf('Resultado: dt = %.8e s\n\n', p.dt);

    fprintf('5) PORTADORA\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Formula usada en la simulacion: fc = 4 * Rs\n');
    fprintf('Sustitucion: fc = 4 * %.2f\n', p.Rs);
    fprintf('Resultado: fc = %.2f Hz\n\n', p.fc);

    fprintf('Chequeo de Nyquist para simulacion discreta:\n');
    fprintf('Fs/2 = %.2f Hz\n', p.Fs/2);
    fprintf('fc = %.2f Hz\n', p.fc);
    fprintf('Condicion basica: fc < Fs/2\n');
    fprintf('Resultado: %.2f < %.2f, se cumple\n\n', p.fc, p.Fs/2);

    fprintf('6) PULSO CONFORMADOR\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Tipo de pulso: %s\n', p.pulseType);
    fprintf('Roll-off: alpha = %.3f\n', p.alpha);
    fprintf('Duracion del pulso: %.0f simbolos\n', p.pulseSpanSymbols);
    fprintf('Muestras por simbolo: %.0f\n', p.sps);
    fprintf('Formula: longitud_pulso = span*sps + 1\n');
    fprintf('Sustitucion: longitud_pulso = %.0f*%.0f + 1\n', ...
        p.pulseSpanSymbols, p.sps);
    fprintf('Resultado: longitud_pulso = %.0f muestras\n\n', ...
        p.pulseLengthSamples);

    fprintf('7) ANCHO DE BANDA TEORICO\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Formula banda base: B = Rb(1 + alpha)/(2 log2(M))\n');
    fprintf('Sustitucion: B = %.2f(1 + %.2f)/(2*%.0f)\n', ...
        p.Rb, p.alpha, p.k);
    fprintf('Resultado: B = %.2f Hz\n\n', p.BW_baseband);

    fprintf('Formula pasabanda: W = Rb(1 + alpha)/log2(M)\n');
    fprintf('Sustitucion: W = %.2f(1 + %.2f)/%.0f\n', ...
        p.Rb, p.alpha, p.k);
    fprintf('Resultado: W = %.2f Hz\n\n', p.BW_passband);

    fprintf('Banda positiva aproximada:\n');
    fprintf('[fc - W/2, fc + W/2] = [%.2f, %.2f] Hz\n\n', ...
        p.fBandPositiveMin, p.fBandPositiveMax);

    fprintf('Banda negativa aproximada:\n');
    fprintf('[-fc - W/2, -fc + W/2] = [%.2f, %.2f] Hz\n\n', ...
        p.fBandNegativeMin, p.fBandNegativeMax);

    fprintf('8) VISUALIZACION Y REPRODUCIBILIDAD\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Trazos del diagrama de ojo: %d\n', p.eyeTraces);
    fprintf('Puntos de constelacion a mostrar: %d\n', ...
        p.constellationPointsToShow);
    fprintf('Semilla aleatoria: rngSeed = %d\n\n', p.rngSeed);

    fprintf('============================================================\n');
    fprintf(' FIN DEL RESUMEN DE PARAMETROS\n');
    fprintf('============================================================\n\n');
end