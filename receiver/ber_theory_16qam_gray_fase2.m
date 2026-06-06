function ber = ber_theory_16qam_gray_fase2(EbN0_dB, M)
    if nargin < 2
        M = 16;
    end

    if M <= 0 || mod(log2(M), 1) ~= 0
        error("M debe ser una potencia de 2.");
    end

    k = log2(M);
    EbN0_linear = 10.^(EbN0_dB ./ 10);

    ber = (4 / k) * (1 - 1 / sqrt(M)) .* ...
          q_function_custom(sqrt((3 * k / (M - 1)) .* EbN0_linear));
end