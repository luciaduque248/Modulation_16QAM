clear;
clc;
close all;

addpath("channel_coding");

rng(1);

n_bits = 1000;
bits_tx = randi([0 1], 1, n_bits);

bits_encoded = hamming74_encode(bits_tx);

bits_decoded = hamming74_decode(bits_encoded, length(bits_tx));

bit_errors = sum(bits_tx ~= bits_decoded);
ber = bit_errors / length(bits_tx);

fprintf("Bits originales: %d\n", length(bits_tx));
fprintf("Bits codificados: %d\n", length(bits_encoded));
fprintf("Tasa del código Hamming(7,4): %.4f\n", 4/7);
fprintf("Errores después de decodificar sin canal: %d\n", bit_errors);
fprintf("BER sin canal: %.6f\n", ber);

if ber == 0
    fprintf("Prueba Hamming(7,4) sin canal: CORRECTA\n");
else
    fprintf("Prueba Hamming(7,4) sin canal: INCORRECTA\n");
end