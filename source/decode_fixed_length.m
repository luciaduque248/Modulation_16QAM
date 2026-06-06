function indices = decode_fixed_length(bits, n_bits)
    bits = bits(:).';

    if mod(length(bits), n_bits) ~= 0
        error("La longitud de bits no es múltiplo de n_bits.");
    end

    bit_matrix = reshape(bits, n_bits, []).';
    weights = 2.^(n_bits-1:-1:0);

    indices = bit_matrix * weights.';
end