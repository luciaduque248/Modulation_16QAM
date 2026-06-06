function bits = encode_fixed_length(indices, n_bits)
    indices = indices(:);

    if any(indices < 0)
        error("Los índices de cuantificación no pueden ser negativos.");
    end

    max_value = 2^n_bits - 1;

    if any(indices > max_value)
        error("Hay índices que exceden el máximo permitido para %d bits.", n_bits);
    end

    bit_matrix = dec2bin(indices, n_bits) - '0';
    bits = reshape(bit_matrix.', 1, []);
end