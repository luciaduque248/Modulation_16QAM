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
samples_to_plot = min(length(x), round(0.03 * Fs));

figure;
plot(t(1:samples_to_plot), x(1:samples_to_plot), "LineWidth", 1);
hold on;
plot(t(1:samples_to_plot), x_rec(1:samples_to_plot), "--", "LineWidth", 1);
grid on;
xlabel("Tiempo [s]");
ylabel("Amplitud");
title("Comparación audio original vs audio reconstruido cuantificado");
legend("Original", "Reconstruido");

figure;
plot(x(1:samples_to_plot), "LineWidth", 1);
hold on;
stairs(x_rec(1:samples_to_plot), "LineWidth", 1);
grid on;
xlabel("Muestra");
ylabel("Amplitud");
title("Efecto de cuantificación sobre el audio");
legend("Original", "Cuantificado");