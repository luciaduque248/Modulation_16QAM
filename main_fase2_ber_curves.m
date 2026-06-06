clear;
clc;
close all;

addpath("source");
addpath("channel_coding");
addpath("transmitter");
addpath("receiver");
addpath("channel");
addpath("visualization");

rng(1);

audio_path = "audio/mi_audio.wav";
min_duration_s = 10;
n_bits_audio = 8;

M = 16;
bits_per_symbol = log2(M);
code_rate = 4/7;

EbN0_dB_vector = 0:2:16;

max_bits_for_ber = 300000;

[x, Fs] = read_audio_source(audio_path, min_duration_s);

[indices_tx, ~, ~, delta] = quantize_audio_uniform(x, n_bits_audio);

bits_source_full = encode_fixed_length(indices_tx, n_bits_audio);

if isfinite(max_bits_for_ber)
    n_bits_used = min(length(bits_source_full), max_bits_for_ber);
    bits_source = bits_source_full(1:n_bits_used);
else
    bits_source = bits_source_full;
end

ber_uncoded_sim = zeros(size(EbN0_dB_vector));
ber_coded_sim = zeros(size(EbN0_dB_vector));
ber_uncoded_theory = zeros(size(EbN0_dB_vector));
ber_coded_theory = zeros(size(EbN0_dB_vector));

fprintf("===== CURVAS BER FASE 2 =====\n");
fprintf("Fs: %d Hz\n", Fs);
fprintf("Duración del audio leído: %.2f s\n", length(x)/Fs);
fprintf("Bits totales del audio: %d\n", length(bits_source_full));
fprintf("Bits usados para curvas: %d\n", length(bits_source));
fprintf("Delta de cuantificación: %.6f\n", delta);
fprintf("Código: Hamming(7,4), Rc = %.4f\n", code_rate);
fprintf("\n");

for idx = 1:length(EbN0_dB_vector)
    EbN0_dB = EbN0_dB_vector(idx);

    symbols_uncoded = map_16qam_gray_fase2(bits_source);

    symbols_uncoded_rx = add_awgn_complex_baseband( ...
        symbols_uncoded, ...
        EbN0_dB, ...
        bits_per_symbol, ...
        1 ...
    );

    bits_uncoded_rx = demap_16qam_gray_fase2( ...
        symbols_uncoded_rx, ...
        length(bits_source) ...
    );

    ber_uncoded_sim(idx) = sum(bits_source ~= bits_uncoded_rx) / length(bits_source);

    bits_coded_tx = hamming74_encode(bits_source);

    symbols_coded = map_16qam_gray_fase2(bits_coded_tx);

    symbols_coded_rx = add_awgn_complex_baseband( ...
        symbols_coded, ...
        EbN0_dB, ...
        bits_per_symbol, ...
        code_rate ...
    );

    bits_coded_rx = demap_16qam_gray_fase2( ...
        symbols_coded_rx, ...
        length(bits_coded_tx) ...
    );

    bits_decoded = hamming74_decode(bits_coded_rx, length(bits_source));

    ber_coded_sim(idx) = sum(bits_source ~= bits_decoded) / length(bits_source);

    ber_uncoded_theory(idx) = ber_theory_16qam_gray_fase2(EbN0_dB, M);

    EbN0_coded_bit_dB = EbN0_dB + 10 * log10(code_rate);

    p_channel_coded = ber_theory_16qam_gray_fase2(EbN0_coded_bit_dB, M);

    ber_coded_theory(idx) = ber_theory_hamming74_bsc(p_channel_coded);

    fprintf("Eb/N0 = %2d dB | BER sin cod. sim = %.8e | BER con Hamming sim = %.8e | BER sin cod. teo = %.8e | BER con Hamming teo = %.8e\n", ...
        EbN0_dB, ...
        ber_uncoded_sim(idx), ...
        ber_coded_sim(idx), ...
        ber_uncoded_theory(idx), ...
        ber_coded_theory(idx));
end

if ~exist("output", "dir")
    mkdir("output");
end

save("output/ber_curves_fase2.mat", ...
    "EbN0_dB_vector", ...
    "ber_uncoded_sim", ...
    "ber_coded_sim", ...
    "ber_uncoded_theory", ...
    "ber_coded_theory", ...
    "M", ...
    "bits_per_symbol", ...
    "code_rate", ...
    "n_bits_audio", ...
    "Fs");

min_ber_plot = 0.5 / length(bits_source);

plot_ber_fase2( ...
    EbN0_dB_vector, ...
    ber_uncoded_sim, ...
    ber_coded_sim, ...
    ber_uncoded_theory, ...
    ber_coded_theory, ...
    min_ber_plot ...
);