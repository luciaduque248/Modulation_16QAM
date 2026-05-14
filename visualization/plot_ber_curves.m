function plot_ber_curves(EbN0_dB, berSim, berTheory, berExact)
% PLOT_BER_CURVES
% Grafica curvas de desempeño BER vs Eb/N0.

    EbN0_dB = EbN0_dB(:);
    berSim = berSim(:);
    berTheory = berTheory(:);

    if length(EbN0_dB) ~= length(berSim) || length(EbN0_dB) ~= length(berTheory) 
        error('EbN0_dB, berSim y berTheory deben tener la misma longitud.');
    end

    figure('Name', 'BER 16-QAM', 'Color', 'w');

    semilogy(EbN0_dB, berSim, 'o-', ...
        'LineWidth', 1.4, ...
        'MarkerSize', 6);
    hold on;
    semilogy(EbN0_dB, berTheory, 's--', ...
        'LineWidth', 1.4, ...
        'MarkerSize', 6);
    
    grid on;

    xlabel('E_b/N_0 [dB]');
    ylabel('BER');
    title('Curvas BER simulada y teórica aproximada - 16-QAM Gray');
    legend('BER simulada', 'BER teórica aproximada', 'Location', 'southwest');

    ylim([1e-6 1]);
end