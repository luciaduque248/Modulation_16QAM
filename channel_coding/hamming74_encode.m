function encoded_bits = hamming74_encode(info_bits)
    info_bits = info_bits(:).';

    if any(info_bits ~= 0 & info_bits ~= 1)
        error("La entrada debe contener solo bits 0 y 1.");
    end

    padding = mod(4 - mod(length(info_bits), 4), 4);

    if padding > 0
        info_bits = [info_bits zeros(1, padding)];
    end

    [G, ~] = hamming74_matrices();

    blocks = reshape(info_bits, 4, []).';
    encoded_blocks = mod(blocks * G, 2);

    encoded_bits = reshape(encoded_blocks.', 1, []);
end