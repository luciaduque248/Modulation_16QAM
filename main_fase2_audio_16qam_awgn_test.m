clear;
clc;
close all;

addpath("source");
addpath("channel_coding");
addpath("transmitter");
addpath("receiver");
addpath("channel");

rng(1);

audio_path = "audio/mi_audio.wav";
min_duration_s = 10;
n_bits_audio = 8;

M = 16;
bits_per_symbol = log2(M);
EbN0_dB = 12;

[x, Fs] = read_audio_source(audio_path, min_duration_s);

[indices_tx, ~, levels, delta] = quantize_audio_uniform(x, n_bits_audio);

bits_source = encode_fixed_length(indices_tx, n_bits_audio);

bits_uncoded_tx = bits_source;

symbols_uncoded = map_16qam_gray_fase2(bits_uncoded_tx);

symbols_uncoded_rx = add_awgn_complex_baseband( ...
    symbols_uncoded, ...
    EbN0_dB, ...
    bits_per_symbol, ...
    1 ...
);

bits_uncoded_rx = demap_16qam_gray_fase2(symbols_uncoded_rx, length(bits_uncoded_tx));

ber_uncoded = sum(bits_uncoded_tx ~= bits_uncoded_rx) / length(bits_uncoded_tx);

bits_coded_tx = hamming74_encode(bits_source);

code_rate = 4/7;

symbols_coded = map_16qam_gray_fase2(bits_coded_tx);

symbols_coded_rx = add_awgn_complex_baseband( ...
    symbols_coded, ...
    EbN0_dB, ...
    bits_per_symbol, ...
    code_rate ...
);

bits_coded_rx = demap_16qam_gray_fase2(symbols_coded_rx, length(bits_coded_tx));

bits_decoded = hamming74_decode(bits_coded_rx, length(bits_source));

ber_coded = sum(bits_source ~= bits_decoded) / length(bits_source);

indices_rx_uncoded = decode_fixed_length(bits_uncoded_rx, n_bits_audio);
x_rec_uncoded = reconstruct_audio_signal(indices_rx_uncoded, levels);

indices_rx_coded = decode_fixed_length(bits_decoded, n_bits_audio);
x_rec_coded = reconstruct_audio_signal(indices_rx_coded, levels);

if ~exist("output", "dir")
    mkdir("output");
end

audiowrite("output/audio_recuperado_sin_hamming_16qam_awgn.wav", x_rec_uncoded, Fs);
audiowrite("output/audio_recuperado_con_hamming_16qam_awgn.wav", x_rec_coded, Fs);

fprintf("===== PRUEBA FASE 2: AUDIO + 16-QAM + AWGN =====\n");
fprintf("Fs: %d Hz\n", Fs);
fprintf("Duración usada: %.2f s\n", length(x)/Fs);
fprintf("Bits por muestra de audio: %d\n", n_bits_audio);
fprintf("Niveles de cuantificación: %d\n", 2^n_bits_audio);
fprintf("Delta de cuantificación: %.6f\n", delta);
fprintf("Bits fuente: %d\n", length(bits_source));
fprintf("Bits codificados Hamming(7,4): %d\n", length(bits_coded_tx));
fprintf("Eb/N0 usado: %.2f dB\n", EbN0_dB);
fprintf("BER sin codificación: %.10f\n", ber_uncoded);
fprintf("BER con Hamming(7,4): %.10f\n", ber_coded);

t = (0:length(x)-1) / Fs;

start_sample = find(abs(x) > 0.02, 1, "first");

if isempty(start_sample)
    start_sample = 1;
end

samples_to_plot = round(0.03 * Fs);
end_sample = min(length(x), start_sample + samples_to_plot - 1);

figure;
plot(t(start_sample:end_sample), x(start_sample:end_sample), "LineWidth", 1);
hold on;
plot(t(start_sample:end_sample), x_rec_uncoded(start_sample:end_sample), "--", "LineWidth", 1);
plot(t(start_sample:end_sample), x_rec_coded(start_sample:end_sample), ":", "LineWidth", 1.3);
grid on;
xlabel("Tiempo [s]");
ylabel("Amplitud");
title("Audio original vs recuperado por 16-QAM sobre AWGN");
legend("Original", "Sin Hamming", "Con Hamming");

figure;
plot(real(symbols_uncoded_rx(1:min(3000, length(symbols_uncoded_rx)))), ...
     imag(symbols_uncoded_rx(1:min(3000, length(symbols_uncoded_rx)))), ...
     ".");
grid on;
xlabel("Componente en fase");
ylabel("Componente en cuadratura");
title("Constelación recibida 16-QAM sin codificación");

figure;
plot(real(symbols_coded_rx(1:min(3000, length(symbols_coded_rx)))), ...
     imag(symbols_coded_rx(1:min(3000, length(symbols_coded_rx)))), ...
     ".");
grid on;
xlabel("Componente en fase");
ylabel("Componente en cuadratura");
title("Constelación recibida 16-QAM con Hamming(7,4)");