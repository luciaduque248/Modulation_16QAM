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
code_rate = 4/7;

EbN0_dB = 12;

samples_per_symbol = 16;
carrier_cycles_per_symbol = 2;

max_bits_passband = 120000;

[x, Fs] = read_audio_source(audio_path, min_duration_s);

[indices_tx, ~, levels, delta] = quantize_audio_uniform(x, n_bits_audio);

bits_source_full = encode_fixed_length(indices_tx, n_bits_audio);

n_bits_used = min(length(bits_source_full), max_bits_passband);
n_bits_used = floor(n_bits_used / n_bits_audio) * n_bits_audio;

bits_source = bits_source_full(1:n_bits_used);

bits_coded_tx = hamming74_encode(bits_source);

symbols_tx = map_16qam_gray_fase2(bits_coded_tx);

tx_passband = modulate_passband_qam_symbols( ...
    symbols_tx, ...
    samples_per_symbol, ...
    carrier_cycles_per_symbol ...
);

rx_passband = add_awgn_real_passband_fase2( ...
    tx_passband, ...
    symbols_tx, ...
    EbN0_dB, ...
    bits_per_symbol, ...
    code_rate ...
);

symbols_rx = demodulate_passband_qam_symbols( ...
    rx_passband, ...
    samples_per_symbol, ...
    carrier_cycles_per_symbol ...
);

bits_coded_rx = demap_16qam_gray_fase2(symbols_rx, length(bits_coded_tx));

bits_decoded = hamming74_decode(bits_coded_rx, length(bits_source));

ber_coded = sum(bits_source ~= bits_decoded) / length(bits_source);

indices_rx = decode_fixed_length(bits_decoded, n_bits_audio);
x_rec = reconstruct_audio_signal(indices_rx, levels);

n_audio_samples_used = length(indices_rx);
x_original_segment = x(1:n_audio_samples_used);

if ~exist("output", "dir")
    mkdir("output");
end

audiowrite("output/audio_recuperado_passband_test.wav", x_rec, Fs);

fprintf("===== PRUEBA PASABANDA FASE 2 =====\n");
fprintf("Fs: %d Hz\n", Fs);
fprintf("Bits usados: %d\n", length(bits_source));
fprintf("Bits codificados Hamming(7,4): %d\n", length(bits_coded_tx));
fprintf("Símbolos 16-QAM transmitidos: %d\n", length(symbols_tx));
fprintf("Muestras pasabanda generadas: %d\n", length(tx_passband));
fprintf("Eb/N0: %.2f dB\n", EbN0_dB);
fprintf("BER con Hamming después de pasabanda: %.10f\n", ber_coded);
fprintf("Delta de cuantificación: %.6f\n", delta);

t = (0:length(x_original_segment)-1) / Fs;

start_sample = find(abs(x_original_segment) > 0.02, 1, "first");

if isempty(start_sample)
    start_sample = 1;
end

samples_to_plot = round(0.03 * Fs);
end_sample = min(length(x_original_segment), start_sample + samples_to_plot - 1);

figure;
plot(t(start_sample:end_sample), x_original_segment(start_sample:end_sample), "LineWidth", 1);
hold on;
plot(t(start_sample:end_sample), x_rec(start_sample:end_sample), "--", "LineWidth", 1);
grid on;
xlabel("Tiempo [s]");
ylabel("Amplitud");
title("Audio original vs recuperado - prueba pasabanda");
legend("Original", "Recuperado");

figure;
plot(tx_passband(1:min(1000, length(tx_passband))), "LineWidth", 1);
grid on;
xlabel("Muestra");
ylabel("Amplitud");
title("Señal pasabanda transmitida");

figure;
plot(real(symbols_rx(1:min(3000, length(symbols_rx)))), ...
     imag(symbols_rx(1:min(3000, length(symbols_rx)))), ...
     ".");
grid on;
xlabel("Componente en fase");
ylabel("Componente en cuadratura");
title("Constelación recibida después de demodulación pasabanda");