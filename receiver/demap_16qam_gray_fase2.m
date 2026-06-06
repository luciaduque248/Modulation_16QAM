function bits = demap_16qam_gray_fase2(received_symbols, original_length)
    received_symbols = received_symbols(:).';

    received_symbols = received_symbols * sqrt(10);

    n_symbols = length(received_symbols);
    bit_matrix = zeros(n_symbols, 4);

    for k = 1:n_symbols
        I = real(received_symbols(k));
        Q = imag(received_symbols(k));

        bit_matrix(k, 1:2) = level_to_gray_pair(I);
        bit_matrix(k, 3:4) = level_to_gray_pair(Q);
    end

    bits = reshape(bit_matrix.', 1, []);

    if nargin == 2
        bits = bits(1:original_length);
    end
end

function pair = level_to_gray_pair(value)
    levels = [-3 -1 1 3];
    gray_bits = [
        0 0;
        0 1;
        1 1;
        1 0
    ];

    [~, idx] = min(abs(value - levels));
    pair = gray_bits(idx, :);
end