function [indices, xq, levels, delta] = quantize_audio_uniform(x, n_bits)
    if n_bits <= 0 || mod(n_bits, 1) ~= 0
        error("n_bits debe ser un entero positivo.");
    end

    x = x(:);

    L = 2^n_bits;
    xmin = -1;
    xmax = 1;

    levels = linspace(xmin, xmax, L);
    delta = levels(2) - levels(1);

    indices = round((x - xmin) / (xmax - xmin) * (L - 1));

    indices(indices < 0) = 0;
    indices(indices > L - 1) = L - 1;

    xq = levels(indices + 1).';
end