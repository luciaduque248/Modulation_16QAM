clear;
clc;
close all;

addpath("channel_coding");

rng(1);

n_bits = 1000;

bits_tx = randi([0 1],1,n_bits);

bits_encoded = hamming74_encode(bits_tx);

received_bits = bits_encoded;

n_blocks = floor(length(received_bits)/7);

for k = 1:n_blocks

    start_idx = (k-1)*7 + 1;
    end_idx = k*7;

    pos_error = randi(7);

    received_bits(start_idx + pos_error - 1) = ...
        mod(received_bits(start_idx + pos_error - 1)+1,2);

end

bits_rx = hamming74_decode(received_bits,length(bits_tx));

bit_errors = sum(bits_tx ~= bits_rx);

ber = bit_errors/length(bits_tx);

fprintf("Errores finales: %d\n",bit_errors);
fprintf("BER final: %.10f\n",ber);