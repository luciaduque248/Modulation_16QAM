clc;
clear;
close all;

% ============================================================
% Proyecto: Sistema 16-QAM Gray sobre canal AWGN
% ============================================================

rootDir = fileparts(mfilename('fullpath'));

addpath(rootDir);
addpath(fullfile(rootDir, 'channel'));
addpath(fullfile(rootDir, 'receiver'));
addpath(fullfile(rootDir, 'transmitter'));
addpath(fullfile(rootDir, 'visualization'));

p = params();

rng(p.rngSeed);

if p.M ~= 16
    error('El proyecto debe ejecutarse con M = 16.');
end

if mod(p.Nbits, p.k) ~= 0
    error('Nbits debe ser múltiplo de log2(M).');
end

% ============================================================
% TRANSMISOR: Bits, mapeo y modulación pasabanda
% ============================================================

bitsTx = generate_bits(p.Nbits);

[symbolsTx, mapInfo] = map_16qam_gray(bitsTx, p);

[txPassband, txInfo] = modulate_passband_16qam(symbolsTx, p);

% ============================================================
% BARRIDO Eb/N0
% ============================================================

berSim = zeros(size(p.EbN0_dB));
berTheory = ber_theory_16qam_gray_approx(p.EbN0_dB, p);

rxSymbolsForPlot = [];
rxIForEye = [];
rxQForEye = [];
rxPassbandForPlot = [];

for idx = 1:length(p.EbN0_dB)

    EbN0current_dB = p.EbN0_dB(idx);
    
    % ================================= CANAL =====================================
    [rxPassband, noiseInfo] = add_awgn_real_passband(txPassband, p, EbN0current_dB);

    % ========= Rx: demodulación, decisión/demapeo y cálculo de BER.================
    [rxSymbols, rxI_mf_sync, rxQ_mf_sync, rxInfo] = demodulate_passband_16qam(rxPassband, p);
    bitsRx = demap_16qam_gray(rxSymbols, p);
    berSim(idx) = compute_ber(bitsTx, bitsRx);
    % ==============================================================================

    fprintf('Eb/N0 = %4.1f dB | BER sim = %.6e | BER teórica = %.6e | N0 = %.6e\n', ...
        EbN0current_dB, berSim(idx), berTheory(idx), noiseInfo.N0);

    if EbN0current_dB == p.EbN0_eye_dB
        rxSymbolsForPlot = rxSymbols;
        rxIForEye = rxI_mf_sync;
        rxQForEye = rxQ_mf_sync;
        rxPassbandForPlot = rxPassband;
    end
end

if isempty(rxSymbolsForPlot)
    rxSymbolsForPlot = rxSymbols;
    rxIForEye = rxI_mf_sync;
    rxQForEye = rxQ_mf_sync;
    rxPassbandForPlot = rxPassband;
end

% ============================================================
% VISUALIZACIÓN
% ============================================================

plot_ber_curves(p.EbN0_dB, berSim, berTheory);
plot_constellation(rxSymbolsForPlot, mapInfo.constellation, p);
plot_eye_diagram(rxIForEye, rxQForEye, p);
plot_spectrum(txPassband, p);

% ============================================================
% VALIDACIÓN DE RESULTADOS
% ============================================================

fprintf('\n================ VALIDACIÓN BÁSICA ================\n');

fprintf('Energía promedio de símbolos transmitidos: %.6f\n', mean(abs(symbolsTx).^2));
fprintf('Energía esperada Es: %.6f\n', p.Es);
fprintf('BER simulada mínima: %.6e\n', min(berSim));
fprintf('BER simulada máxima: %.6e\n', max(berSim));

if berSim(end) >= berSim(1)
    warning('La BER simulada no disminuyó. Revise receptor, ruido o sincronización.');
end

if berSim(end) > 1e-2
    warning('La BER a Eb/N0 alto sigue siendo grande. El sistema aún puede tener errores de recepción.');
end

fprintf('====================================================\n');

% ============================================================
% RESUMEN
% ============================================================

fprintf('\n================ RESUMEN DEL SISTEMA ================\n');
fprintf('Modulación: 16-QAM Gray\n');
fprintf('M = %d\n', p.M);
fprintf('k = log2(M) = %d\n', p.k);
fprintf('Número de bits transmitidos = %d\n', p.Nbits);
fprintf('Número de símbolos transmitidos = %d\n', length(symbolsTx));
fprintf('Rb = %.1f bit/s\n', p.Rb);
fprintf('Rs = %.1f símbolos/s\n', p.Rs);
fprintf('Fs = %.1f Hz\n', p.Fs);
fprintf('fc = %.1f Hz\n', p.fc);
fprintf('Es = %.1f\n', p.Es);
fprintf('Eb = %.1f\n', p.Eb);
fprintf('Roll-off alpha = %.2f\n', p.alpha);
fprintf('Ancho de banda baseband teórico B = %.3f Hz\n', p.BW_baseband);
fprintf('Ancho de banda pasabanda teórico W = %.3f Hz\n', p.BW_passband);
fprintf('=====================================================\n');