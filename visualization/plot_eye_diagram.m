function plot_eye_diagram(I_mf_sync, Q_mf_sync, p)
% PLOT_EYE_DIAGRAM
% Diagrama de ojo manual para ramas I y Q.
%
% No usa eyediagram.
%
% Cada traza cubre 2T.
% El instante óptimo de muestreo queda en t/T = 0.

    I_mf_sync = I_mf_sync(:);
    Q_mf_sync = Q_mf_sync(:);

    if isempty(I_mf_sync) || isempty(Q_mf_sync)
        error('Las señales del ojo no pueden estar vacías.');
    end

    if length(I_mf_sync) ~= length(Q_mf_sync)
        error('Las ramas I y Q deben tener la misma longitud.');
    end

    samplesPerTrace = 2 * p.sps;

    timeAxis = ((0:samplesPerTrace-1).' - p.sps) / p.sps;

    NsymbolsAvailable = floor(length(I_mf_sync) / p.sps);

    if NsymbolsAvailable < 4
        error('No hay suficientes símbolos para graficar el ojo.');
    end

    Ntraces = min(p.eyeTraces, NsymbolsAvailable - 3);

    figure('Name', 'Diagrama de ojo 16-QAM', 'Color', 'w');

    subplot(2, 1, 1);
    hold on;

    for n = 2:(Ntraces + 1)

        centerIndex = 1 + (n - 1)*p.sps;
        startIndex = centerIndex - p.sps;
        endIndex = centerIndex + p.sps - 1;

        if startIndex >= 1 && endIndex <= length(I_mf_sync)
            segment = I_mf_sync(startIndex:endIndex);
            plot(timeAxis, segment, 'b');
        end
    end

    xline(0, 'r--', 'LineWidth', 1.2);
    grid on;
    xlim([-1 1]);

    xlabel('Tiempo normalizado a T');
    ylabel('Amplitud');
    title('Diagrama de ojo en fase');

    subplot(2, 1, 2);
    hold on;

    for n = 2:(Ntraces + 1)

        centerIndex = 1 + (n - 1)*p.sps;
        startIndex = centerIndex - p.sps;
        endIndex = centerIndex + p.sps - 1;

        if startIndex >= 1 && endIndex <= length(Q_mf_sync)
            segment = Q_mf_sync(startIndex:endIndex);
            plot(timeAxis, segment, 'm');
        end
    end

    xline(0, 'r--', 'LineWidth', 1.2);
    grid on;
    xlim([-1 1]);

    xlabel('Tiempo normalizado a T');
    ylabel('Amplitud');
    title('Diagrama de ojo en cuadratura');
end