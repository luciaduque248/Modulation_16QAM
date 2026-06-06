function ber_out = ber_theory_hamming74_bsc(p)
    p_original_shape = size(p);
    p = p(:);

    ber_out_column = zeros(size(p));

    error_patterns = generate_error_patterns_7bits();
    pattern_weights = sum(error_patterns, 2);

    info_error_count = zeros(size(error_patterns, 1), 1);

    for i = 1:size(error_patterns, 1)
        decoded_error = hamming74_decode(error_patterns(i, :), 4);
        info_error_count(i) = sum(decoded_error ~= zeros(1, 4));
    end

    for k = 1:length(p)
        pk = p(k);

        probabilities = (pk .^ pattern_weights) .* ...
                        ((1 - pk) .^ (7 - pattern_weights));

        ber_out_column(k) = sum(probabilities .* info_error_count) / 4;
    end

    ber_out = reshape(ber_out_column, p_original_shape);
end

function patterns = generate_error_patterns_7bits()
    patterns = zeros(128, 7);

    for value = 0:127
        for bit_position = 1:7
            patterns(value + 1, bit_position) = bitget(value, 8 - bit_position);
        end
    end
end