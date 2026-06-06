function [indices, xq, levels, delta] = quantize_audio_uniform(x, n_bits)
    if n_bits <= 0 || mod(n_bits, 1) ~= 0
        error("n_bits debe ser un entero positivo.");
    end

    L = 2^n_bits;
    xmin = -1;
    xmax = 1;

    delta = (xmax - xmin) / L;

    indices = floor((x - xmin) / delta);
    indices(indices < 0) = 0;
    indices(indices > L - 1) = L - 1;

    levels = xmin + ((0:L-1) + 0.5) * delta;
    xq = levels(indices + 1).';
end