clear;
clc;
close all;

addpath("source");
addpath("channel_coding");

audio_path = "audio/mi_audio.wav";
min_duration_s = 10;
n_bits = 8;

[x, Fs] = read_audio_source(audio_path, min_duration_s);

[indices_tx, ~, levels, delta] = quantize_audio_uniform(x, n_bits);

bits_tx = encode_fixed_length(indices_tx, n_bits);

bits_encoded = hamming74_encode(bits_tx);

bits_decoded = hamming74_decode(bits_encoded, length(bits_tx));

indices_rx = decode_fixed_length(bits_decoded, n_bits);

x_rec = reconstruct_audio_signal(indices_rx, levels);

bit_errors = sum(bits_tx ~= bits_decoded);
ber = bit_errors / length(bits_tx);

bit_rate_source = Fs * n_bits;
code_rate = 4/7;
bit_rate_coded = bit_rate_source / code_rate;

fprintf("Frecuencia de muestreo Fs: %d Hz\n", Fs);
fprintf("Duración usada: %.2f s\n", length(x)/Fs);
fprintf("Bits por muestra: %d\n", n_bits);
fprintf("Número de niveles: %d\n", 2^n_bits);
fprintf("Paso de cuantificación delta: %.6f\n", delta);
fprintf("Bits fuente: %d\n", length(bits_tx));
fprintf("Bits codificados Hamming(7,4): %d\n", length(bits_encoded));
fprintf("Tasa fuente: %.2f bps\n", bit_rate_source);
fprintf("Tasa codificada: %.2f bps\n", bit_rate_coded);
fprintf("BER después de Hamming sin canal: %.10f\n", ber);

if ~exist("output", "dir")
    mkdir("output");
end

audiowrite("output/audio_reconstruido_audio_hamming.wav", x_rec, Fs);

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
plot(t(start_sample:end_sample), x_rec(start_sample:end_sample), "--", "LineWidth", 1);
grid on;
xlabel("Tiempo [s]");
ylabel("Amplitud");
title("Audio original vs reconstruido después de Hamming(7,4) sin canal");
legend("Original", "Reconstruido");

figure;
stem(bits_tx(1:80), "filled");
hold on;
stem(bits_decoded(1:80), "--");
grid on;
xlabel("Índice de bit");
ylabel("Valor");
title("Comparación de bits fuente vs bits recuperados");
legend("Bits fuente", "Bits recuperados");