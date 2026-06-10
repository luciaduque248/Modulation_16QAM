clear;
clc;
close all;

addpath("source");
addpath("channel_coding");
addpath("transmitter");
addpath("receiver");
addpath("channel");
addpath("visualization");

cfg = params_fase2();

rng(cfg.random_seed);

if ~exist(cfg.output_dir, "dir")
    mkdir(cfg.output_dir);
end

generated_files = {};

fprintf("====================================================\n");
fprintf(" SISTEMA DE COMUNICACIÓN DIGITAL - FASE II\n");
fprintf(" Audio + Hamming(7,4) + 16-QAM + AWGN\n");
fprintf("====================================================\n\n");

%% ============================================================
% 1. Conversión A/D del audio
% ============================================================

fprintf("1) Conversión A/D del audio\n");

[x, Fs] = read_audio_source(cfg.audio_path, cfg.min_duration_s);

bits_audio = cfg.n_bits_audio;

[indices_tx, xq, levels, delta] = quantize_audio_uniform(x, bits_audio);

bits_source = encode_fixed_length(indices_tx, bits_audio);

indices_adc_rx = decode_fixed_length(bits_source, bits_audio);
x_adc_rec = reconstruct_audio_signal(indices_adc_rx, levels);

bit_rate_source = Fs * bits_audio;

file_adc_audio = fullfile(cfg.output_dir, "fase2_audio_01_reconstruido_adc.wav");
audiowrite(file_adc_audio, x_adc_rec, Fs);
generated_files = register_generated_file(generated_files, file_adc_audio);

fprintf("Fs: %d Hz\n", Fs);
fprintf("Duración usada: %.2f s\n", length(x)/Fs);
fprintf("Bits por muestra: %d\n", bits_audio);
fprintf("Niveles de cuantificación: %d\n", 2^bits_audio);
fprintf("Delta de cuantificación: %.6f\n", delta);
fprintf("Bits fuente: %d\n", length(bits_source));
fprintf("Tasa fuente: %.2f bps\n\n", bit_rate_source);

%% ============================================================
% 2. Validación de Hamming(7,4) sin canal
% ============================================================

fprintf("2) Validación Hamming(7,4) sin canal\n");

bits_hamming_tx = hamming74_encode(bits_source);
bits_hamming_rx = hamming74_decode(bits_hamming_tx, length(bits_source));

ber_hamming_no_channel = sum(bits_source ~= bits_hamming_rx) / length(bits_source);

fprintf("Bits codificados Hamming(7,4): %d\n", length(bits_hamming_tx));
fprintf("Tasa del código Rc: %.4f\n", cfg.code_rate);
fprintf("BER Hamming sin canal: %.10f\n\n", ber_hamming_no_channel);

%% ============================================================
% 3. Comparación audio: sin codificación vs con Hamming en AWGN
% ============================================================

fprintf("3) Audio sobre 16-QAM + AWGN en banda base equivalente\n");

symbols_uncoded = map_16qam_gray_fase2(bits_source);

symbols_uncoded_rx = add_awgn_complex_baseband( ...
    symbols_uncoded, ...
    cfg.EbN0_single_dB, ...
    cfg.bits_per_symbol, ...
    1 ...
);

bits_uncoded_rx = demap_16qam_gray_fase2(symbols_uncoded_rx, length(bits_source));

ber_uncoded_single = sum(bits_source ~= bits_uncoded_rx) / length(bits_source);

indices_uncoded_rx = decode_fixed_length(bits_uncoded_rx, bits_audio);
x_uncoded_rec = reconstruct_audio_signal(indices_uncoded_rx, levels);

bits_coded_tx = hamming74_encode(bits_source);

symbols_coded = map_16qam_gray_fase2(bits_coded_tx);

symbols_coded_rx = add_awgn_complex_baseband( ...
    symbols_coded, ...
    cfg.EbN0_single_dB, ...
    cfg.bits_per_symbol, ...
    cfg.code_rate ...
);

bits_coded_rx = demap_16qam_gray_fase2(symbols_coded_rx, length(bits_coded_tx));

bits_decoded = hamming74_decode(bits_coded_rx, length(bits_source));

ber_coded_single = sum(bits_source ~= bits_decoded) / length(bits_source);

indices_coded_rx = decode_fixed_length(bits_decoded, bits_audio);
x_coded_rec = reconstruct_audio_signal(indices_coded_rx, levels);

file_uncoded_audio = fullfile(cfg.output_dir, "fase2_audio_02_sin_hamming_16qam_awgn.wav");
file_coded_audio = fullfile(cfg.output_dir, "fase2_audio_03_con_hamming_16qam_awgn.wav");

audiowrite(file_uncoded_audio, x_uncoded_rec, Fs);
audiowrite(file_coded_audio, x_coded_rec, Fs);

generated_files = register_generated_file(generated_files, file_uncoded_audio);
generated_files = register_generated_file(generated_files, file_coded_audio);

fprintf("Eb/N0 usado: %.2f dB\n", cfg.EbN0_single_dB);
fprintf("BER sin codificación: %.10f\n", ber_uncoded_single);
fprintf("BER con Hamming(7,4): %.10f\n\n", ber_coded_single);

file_audio_baseband_fig = plot_audio_comparison_final( ...
    x, ...
    x_uncoded_rec, ...
    x_coded_rec, ...
    Fs, ...
    "Audio original vs recuperado por 16-QAM sobre AWGN", ...
    cfg ...
);

generated_files = register_generated_file(generated_files, file_audio_baseband_fig);


%% ============================================================
% 4. Curvas BER vs Eb/N0
% ============================================================

fprintf("4) Curvas BER vs Eb/N0\n");

n_bits_used = min(length(bits_source), cfg.max_bits_for_ber);
bits_ber = bits_source(1:n_bits_used);

ber_uncoded_sim = zeros(size(cfg.EbN0_dB_vector));
ber_coded_sim = zeros(size(cfg.EbN0_dB_vector));
ber_uncoded_theory = zeros(size(cfg.EbN0_dB_vector));
ber_coded_theory = zeros(size(cfg.EbN0_dB_vector));

for idx = 1:length(cfg.EbN0_dB_vector)
    EbN0_dB = cfg.EbN0_dB_vector(idx);

    symbols_uncoded_ber = map_16qam_gray_fase2(bits_ber);

    symbols_uncoded_ber_rx = add_awgn_complex_baseband( ...
        symbols_uncoded_ber, ...
        EbN0_dB, ...
        cfg.bits_per_symbol, ...
        1 ...
    );

    bits_uncoded_ber_rx = demap_16qam_gray_fase2( ...
        symbols_uncoded_ber_rx, ...
        length(bits_ber) ...
    );

    ber_uncoded_sim(idx) = sum(bits_ber ~= bits_uncoded_ber_rx) / length(bits_ber);

    bits_coded_ber_tx = hamming74_encode(bits_ber);

    symbols_coded_ber = map_16qam_gray_fase2(bits_coded_ber_tx);

    symbols_coded_ber_rx = add_awgn_complex_baseband( ...
        symbols_coded_ber, ...
        EbN0_dB, ...
        cfg.bits_per_symbol, ...
        cfg.code_rate ...
    );

    bits_coded_ber_rx = demap_16qam_gray_fase2( ...
        symbols_coded_ber_rx, ...
        length(bits_coded_ber_tx) ...
    );

    bits_decoded_ber = hamming74_decode(bits_coded_ber_rx, length(bits_ber));

    ber_coded_sim(idx) = sum(bits_ber ~= bits_decoded_ber) / length(bits_ber);

    ber_uncoded_theory(idx) = ber_theory_16qam_gray_fase2(EbN0_dB, cfg.M);

    EbN0_coded_bit_dB = EbN0_dB + 10 * log10(cfg.code_rate);
    p_channel_coded = ber_theory_16qam_gray_fase2(EbN0_coded_bit_dB, cfg.M);

    ber_coded_theory(idx) = ber_theory_hamming74_bsc(p_channel_coded);

    fprintf("Eb/N0 = %2d dB | Sin cod. sim = %.8e | Hamming sim = %.8e | Sin cod. teo = %.8e | Hamming teo = %.8e\n", ...
        EbN0_dB, ...
        ber_uncoded_sim(idx), ...
        ber_coded_sim(idx), ...
        ber_uncoded_theory(idx), ...
        ber_coded_theory(idx));
end

min_ber_plot = 0.5 / length(bits_ber);

plot_ber_fase2( ...
    cfg.EbN0_dB_vector, ...
    ber_uncoded_sim, ...
    ber_coded_sim, ...
    ber_uncoded_theory, ...
    ber_coded_theory, ...
    min_ber_plot ...
);

file_ber_fig = "";

if cfg.save_figures
    file_ber_fig = fullfile(cfg.output_dir, "fase2_fig_ber_curves.png");
    saveas(gcf, file_ber_fig);
end

generated_files = register_generated_file(generated_files, file_ber_fig);

fprintf("\n");

%% ============================================================
% 5. Prueba pasabanda con Hamming(7,4)
% ============================================================

fprintf("5) Prueba pasabanda\n");

n_bits_passband = min(length(bits_source), cfg.max_bits_passband);
n_bits_passband = floor(n_bits_passband / bits_audio) * bits_audio;

bits_passband = bits_source(1:n_bits_passband);

bits_passband_coded_tx = hamming74_encode(bits_passband);

symbols_passband_tx = map_16qam_gray_fase2(bits_passband_coded_tx);

tx_passband = modulate_passband_qam_symbols( ...
    symbols_passband_tx, ...
    cfg.samples_per_symbol, ...
    cfg.carrier_cycles_per_symbol ...
);

rx_passband = add_awgn_real_passband_fase2( ...
    tx_passband, ...
    symbols_passband_tx, ...
    cfg.EbN0_single_dB, ...
    cfg.bits_per_symbol, ...
    cfg.code_rate ...
);

symbols_passband_rx = demodulate_passband_qam_symbols( ...
    rx_passband, ...
    cfg.samples_per_symbol, ...
    cfg.carrier_cycles_per_symbol ...
);

bits_passband_coded_rx = demap_16qam_gray_fase2( ...
    symbols_passband_rx, ...
    length(bits_passband_coded_tx) ...
);

bits_passband_decoded = hamming74_decode(bits_passband_coded_rx, length(bits_passband));

ber_passband = sum(bits_passband ~= bits_passband_decoded) / length(bits_passband);

indices_passband_rx = decode_fixed_length(bits_passband_decoded, bits_audio);
x_passband_rec = reconstruct_audio_signal(indices_passband_rx, levels);

n_audio_samples_passband = length(indices_passband_rx);
x_passband_original = x(1:n_audio_samples_passband);

file_passband_audio = fullfile(cfg.output_dir, "fase2_audio_04_recuperado_pasabanda.wav");
audiowrite(file_passband_audio, x_passband_rec, Fs);
generated_files = register_generated_file(generated_files, file_passband_audio);

fprintf("Bits usados en pasabanda: %d\n", length(bits_passband));
fprintf("Bits codificados en pasabanda: %d\n", length(bits_passband_coded_tx));
fprintf("Símbolos 16-QAM pasabanda: %d\n", length(symbols_passband_tx));
fprintf("Muestras pasabanda: %d\n", length(tx_passband));
fprintf("BER pasabanda con Hamming: %.10f\n\n", ber_passband);

file_audio_passband_fig = plot_audio_passband_final(x_passband_original, x_passband_rec, Fs, cfg);
file_tx_passband_fig = plot_tx_passband_final(tx_passband, cfg);
file_constellation_passband_fig = plot_constellation_passband_final(symbols_passband_rx, cfg);

generated_files = register_generated_file(generated_files, file_audio_passband_fig);
generated_files = register_generated_file(generated_files, file_tx_passband_fig);
generated_files = register_generated_file(generated_files, file_constellation_passband_fig);

%% ============================================================
% 6. Guardar resultados
% ============================================================

fprintf("6) Guardar resultados\n");

results = struct();

results.Fs = Fs;
results.n_bits_audio = bits_audio;
results.quantization_levels = 2^bits_audio;
results.delta = delta;
results.source_bit_rate_bps = bit_rate_source;
results.source_bits = length(bits_source);
results.hamming_bits = length(bits_hamming_tx);
results.code_rate = cfg.code_rate;

results.EbN0_single_dB = cfg.EbN0_single_dB;
results.ber_uncoded_single = ber_uncoded_single;
results.ber_coded_single = ber_coded_single;
results.ber_passband = ber_passband;

results.EbN0_dB_vector = cfg.EbN0_dB_vector;
results.ber_uncoded_sim = ber_uncoded_sim;
results.ber_coded_sim = ber_coded_sim;
results.ber_uncoded_theory = ber_uncoded_theory;
results.ber_coded_theory = ber_coded_theory;

file_results = fullfile(cfg.output_dir, "fase2_results.mat");
save(file_results, "results", "cfg");
generated_files = register_generated_file(generated_files, file_results);

fprintf("Resultados guardados correctamente.\n\n");

%% ============================================================
% 7. Listado final de archivos generados
% ============================================================

fprintf("7) Listado de archivos generados\n");
print_generated_files(generated_files, cfg.output_dir);

fprintf("\nEjecución final completada.\n");

%% ============================================================
% Funciones locales de visualización y registro
% ============================================================

function file_path = plot_audio_comparison_final(x, x_uncoded_rec, x_coded_rec, Fs, figure_title, cfg)
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
    plot(t(start_sample:end_sample), x_uncoded_rec(start_sample:end_sample), "--", "LineWidth", 1);
    plot(t(start_sample:end_sample), x_coded_rec(start_sample:end_sample), ":", "LineWidth", 1.3);
    grid on;
    xlabel("Tiempo [s]");
    ylabel("Amplitud");
    title(figure_title);
    legend("Original", "Sin Hamming", "Con Hamming");

    file_path = "";

    if cfg.save_figures
        file_path = fullfile(cfg.output_dir, "fase2_fig_audio_baseband_comparison.png");
        saveas(gcf, file_path);
    end
end

function file_path = plot_audio_passband_final(x_original, x_rec, Fs, cfg)
    t = (0:length(x_original)-1) / Fs;

    start_sample = find(abs(x_original) > 0.02, 1, "first");

    if isempty(start_sample)
        start_sample = 1;
    end

    samples_to_plot = round(0.03 * Fs);
    end_sample = min(length(x_original), start_sample + samples_to_plot - 1);

    figure;
    plot(t(start_sample:end_sample), x_original(start_sample:end_sample), "LineWidth", 1);
    hold on;
    plot(t(start_sample:end_sample), x_rec(start_sample:end_sample), "--", "LineWidth", 1);
    grid on;
    xlabel("Tiempo [s]");
    ylabel("Amplitud");
    title("Audio original vs recuperado - prueba pasabanda");
    legend("Original", "Recuperado");

    file_path = "";

    if cfg.save_figures
        file_path = fullfile(cfg.output_dir, "fase2_fig_audio_passband_comparison.png");
        saveas(gcf, file_path);
    end
end

function file_path = plot_tx_passband_final(tx_passband, cfg)
    figure;
    plot(tx_passband(1:min(1000, length(tx_passband))), "LineWidth", 1);
    grid on;
    xlabel("Muestra");
    ylabel("Amplitud");
    title("Señal pasabanda transmitida");

    file_path = "";

    if cfg.save_figures
        file_path = fullfile(cfg.output_dir, "fase2_fig_tx_passband.png");
        saveas(gcf, file_path);
    end
end

function file_path = plot_constellation_passband_final(symbols_rx, cfg)
    figure;
    plot(real(symbols_rx(1:min(3000, length(symbols_rx)))), ...
         imag(symbols_rx(1:min(3000, length(symbols_rx)))), ...
         ".");
    grid on;
    xlabel("Componente en fase");
    ylabel("Componente en cuadratura");
    title("Constelación recibida después de demodulación pasabanda");

    file_path = "";

    if cfg.save_figures
        file_path = fullfile(cfg.output_dir, "fase2_fig_constellation_passband.png");
        saveas(gcf, file_path);
    end
end

function generated_files = register_generated_file(generated_files, file_path)
    if isempty(file_path)
        return;
    end

    if strlength(string(file_path)) == 0
        return;
    end

    generated_files{end + 1} = char(file_path);
end

function print_generated_files(generated_files, output_dir)
    if isempty(generated_files)
        fprintf("No se registraron archivos generados.\n");
        return;
    end

    fprintf("Carpeta de salida: %s\n", output_dir);
    fprintf("Total de archivos generados: %d\n\n", length(generated_files));

    for k = 1:length(generated_files)
        file_path = generated_files{k};

        if exist(file_path, "file")
            file_info = dir(file_path);
            file_size_kb = file_info.bytes / 1024;

            fprintf("%02d. %s | %.2f KB\n", ...
                k, ...
                file_path, ...
                file_size_kb);
        else
            fprintf("%02d. %s | ADVERTENCIA: no se encontró el archivo\n", ...
                k, ...
                file_path);
        end
    end
end