function symbols = map_16qam_gray_fase2(bits)
    bits = bits(:).';

    if any(bits ~= 0 & bits ~= 1)
        error("La entrada debe contener solo bits 0 y 1.");
    end

    padding = mod(4 - mod(length(bits), 4), 4);

    if padding > 0
        bits = [bits zeros(1, padding)];
    end

    bit_blocks = reshape(bits, 4, []).';

    n_symbols = size(bit_blocks, 1);
    symbols = zeros(1, n_symbols);

    for k = 1:n_symbols
        b1 = bit_blocks(k, 1);
        b2 = bit_blocks(k, 2);
        b3 = bit_blocks(k, 3);
        b4 = bit_blocks(k, 4);

        I = gray_pair_to_level(b1, b2);
        Q = gray_pair_to_level(b3, b4);

        symbols(k) = I + 1j * Q;
    end

    symbols = symbols / sqrt(10);
end

function level = gray_pair_to_level(b1, b2)
    if b1 == 0 && b2 == 0
        level = -3;
    elseif b1 == 0 && b2 == 1
        level = -1;
    elseif b1 == 1 && b2 == 1
        level = 1;
    elseif b1 == 1 && b2 == 0
        level = 3;
    else
        error("Par de bits inválido.");
    end
end