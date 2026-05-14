function plot_spectrum(x, p)
% PLOT_SPECTRUM
% Grafica el espectro normalizado de la señal pasabanda transmitida.
%
% También marca:
%   - frecuencia portadora fc
%   - banda teórica ocupada alrededor de +fc
%   - banda teórica ocupada alrededor de -fc
%
% Para pasabanda, según Cap. 3:
%   W = Rb(1 + alpha)/log2(M)

    x = x(:);

    if isempty(x)
        error('La señal para graficar espectro no puede estar vacía.');
    end

    if ~isreal(x)
        error('El espectro pasabanda esperado corresponde a una señal real.');
    end

    Nfft = 2^nextpow2(length(x));

    X = fftshift(fft(x, Nfft));
    f = (-Nfft/2:Nfft/2-1).' * (p.Fs / Nfft);

    magnitude = abs(X);
    magnitude = magnitude / max(magnitude + eps);

    magnitudeDB = 20*log10(magnitude + 1e-12);

    figure('Name', 'Espectro', 'Color', 'w');

    plot(f, magnitudeDB, 'LineWidth', 1.1);
    hold on;
    grid on;

    xlabel('Frecuencia [Hz]');
    ylabel('Magnitud normalizada [dB]');
    title('Espectro de la señal modulada en pasabanda');

    % Límites teóricos de banda alrededor de +fc y -fc
    BW = p.BW_passband;

    f1_pos = p.fc - BW/2;
    f2_pos = p.fc + BW/2;

    f1_neg = -p.fc - BW/2;
    f2_neg = -p.fc + BW/2;

    xline(p.fc, 'r--', 'LineWidth', 1.2);
    xline(-p.fc, 'r--', 'LineWidth', 1.2);

    xline(f1_pos, 'k--', 'LineWidth', 1.0);
    xline(f2_pos, 'k--', 'LineWidth', 1.0);
    xline(f1_neg, 'k--', 'LineWidth', 1.0);
    xline(f2_neg, 'k--', 'LineWidth', 1.0);

    legend('Espectro normalizado', ...
           '+f_c', ...
           '-f_c', ...
           'Límites de banda teóricos', ...
           'Location', 'best');

    fprintf('\n================ ESPECTRO ================\n');
    fprintf('Frecuencia portadora fc = %.3f Hz\n', p.fc);
    fprintf('Roll-off alpha = %.3f\n', p.alpha);
    fprintf('Ancho de banda pasabanda teórico W = %.3f Hz\n', p.BW_passband);
    fprintf('Banda positiva aproximada: [%.3f, %.3f] Hz\n', f1_pos, f2_pos);
    fprintf('Banda negativa aproximada: [%.3f, %.3f] Hz\n', f1_neg, f2_neg);
    fprintf('==========================================\n');
end