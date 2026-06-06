function decoded_bits = hamming74_decode(received_bits, original_length)
    received_bits = received_bits(:).';

    if any(received_bits ~= 0 & received_bits ~= 1)
        error("La entrada debe contener solo bits 0 y 1.");
    end

    if mod(length(received_bits), 7) ~= 0
        error("La longitud recibida debe ser múltiplo de 7.");
    end

    [~, H] = hamming74_matrices();

    received_blocks = reshape(received_bits, 7, []).';
    corrected_blocks = received_blocks;

    for i = 1:size(received_blocks, 1)
        r = received_blocks(i, :);
        syndrome = mod(H * r.', 2);

        if any(syndrome)
            error_position = find_syndrome_position(H, syndrome);

            if error_position > 0
                corrected_blocks(i, error_position) = mod(corrected_blocks(i, error_position) + 1, 2);
            end
        end
    end

    decoded_matrix = corrected_blocks(:, 1:4);
    decoded_bits = reshape(decoded_matrix.', 1, []);

    if nargin == 2
        decoded_bits = decoded_bits(1:original_length);
    end
end

function error_position = find_syndrome_position(H, syndrome)
    error_position = 0;

    for col = 1:size(H, 2)
        if isequal(H(:, col), syndrome)
            error_position = col;
            return;
        end
    end
end