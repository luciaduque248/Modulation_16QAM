clear;
clc;
close all;

addpath("source");

audio_path = "audio/mi_audio.wav";
min_duration_s = 10;
n_bits = 8;

[x, Fs] = read_audio_source(audio_path, min_duration_s);

[indices_tx, xq, levels, delta] = quantize_audio_uniform(x, n_bits);

bits_tx = encode_fixed_length(indices_tx, n_bits);

indices_rx = decode_fixed_length(bits_tx, n_bits);

x_rec = reconstruct_audio_signal(indices_rx, levels);

bit_rate = Fs * n_bits;

fprintf("Frecuencia de muestreo Fs: %d Hz\n", Fs);
fprintf("Duración usada: %.2f s\n", length(x)/Fs);
fprintf("Bits por muestra: %d\n", n_bits);
fprintf("Número de niveles: %d\n", 2^n_bits);
fprintf("Paso de cuantificación delta: %.6f\n", delta);
fprintf("Tasa de transmisión: %.2f bps\n", bit_rate);
fprintf("Total de bits generados: %d bits\n", length(bits_tx));

if ~exist("output", "dir")
    mkdir("output");
end

audiowrite("output/audio_reconstruido_adc.wav", x_rec, Fs);

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
title("Comparación audio original vs audio reconstruido cuantificado");
legend("Original", "Reconstruido");

figure;
plot(x(start_sample:end_sample), "LineWidth", 1);
hold on;
stairs(x_rec(start_sample:end_sample), "LineWidth", 1);
grid on;
xlabel("Muestra");
ylabel("Amplitud");
title("Efecto de cuantificación sobre el audio");
legend("Original", "Cuantificado");