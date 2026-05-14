function plot_constellation(rxSymbols, idealConstellation, p)
% PLOT_CONSTELLATION
% Diagrama de constelación recibido antes del decisor.

    rxSymbols = rxSymbols(:);
    idealConstellation = idealConstellation(:);

    if isempty(rxSymbols)
        error('No hay símbolos recibidos para graficar.');
    end

    if isempty(idealConstellation)
        error('La constelación ideal está vacía.');
    end

    Nshow = min(length(rxSymbols), p.constellationPointsToShow);
    rxShow = rxSymbols(1:Nshow);

    figure('Name', 'Constelación 16-QAM', 'Color', 'w');

    plot(real(rxShow), imag(rxShow), '.', ...
        'MarkerSize', 7);

    hold on;

    plot(real(idealConstellation), imag(idealConstellation), 'ro', ...
        'MarkerSize', 10, ...
        'LineWidth', 1.5);

    grid on;
    axis equal;

    xlabel('En fase');
    ylabel('Cuadratura');
    title('Constelación recibida - 16-QAM');

    legend('Símbolos recibidos', 'Constelación ideal', 'Location', 'best');

    maxIdeal = max(abs([real(idealConstellation); imag(idealConstellation)]));
    maxRx = prctile(abs([real(rxShow); imag(rxShow)]), 99);

    axisLimit = max(maxIdeal + 0.5, maxRx + 0.5);

    xlim([-axisLimit axisLimit]);
    ylim([-axisLimit axisLimit]);

    fprintf('\n============= CONSTELACIÓN =============\n');
    fprintf('Símbolos graficados: %d\n', Nshow);
    fprintf('Esquema: 16-QAM Gray\n');
    fprintf('Escala ideal: 1/sqrt(10)\n');
    fprintf('========================================\n');
end