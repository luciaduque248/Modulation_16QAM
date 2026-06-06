function plot_ber_fase2(EbN0_dB_vector, ber_uncoded_sim, ber_coded_sim, ber_uncoded_theory, ber_coded_theory, min_ber_plot)
    if nargin < 6
        min_ber_plot = 1e-6;
    end

    ber_uncoded_sim_plot = replace_zeros_for_log_plot(ber_uncoded_sim, min_ber_plot);
    ber_coded_sim_plot = replace_zeros_for_log_plot(ber_coded_sim, min_ber_plot);
    ber_uncoded_theory_plot = replace_zeros_for_log_plot(ber_uncoded_theory, min_ber_plot);
    ber_coded_theory_plot = replace_zeros_for_log_plot(ber_coded_theory, min_ber_plot);

    figure;
    semilogy(EbN0_dB_vector, ber_uncoded_sim_plot, "o-", "LineWidth", 1.2);
    hold on;
    semilogy(EbN0_dB_vector, ber_coded_sim_plot, "s-", "LineWidth", 1.2);
    semilogy(EbN0_dB_vector, ber_uncoded_theory_plot, "--", "LineWidth", 1.2);
    semilogy(EbN0_dB_vector, ber_coded_theory_plot, ":", "LineWidth", 1.5);

    grid on;
    xlabel("Eb/N0 [dB]");
    ylabel("BER");
    title("Curvas BER vs Eb/N0 - 16-QAM sobre AWGN");
    legend( ...
        "Simulada sin codificación", ...
        "Simulada con Hamming(7,4)", ...
        "Teórica sin codificación", ...
        "Teórica con Hamming(7,4)", ...
        "Location", "southwest" ...
    );
end

function ber_plot = replace_zeros_for_log_plot(ber_values, min_ber_plot)
    ber_plot = ber_values;
    ber_plot(ber_plot == 0) = min_ber_plot;
end