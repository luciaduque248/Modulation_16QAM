function y = add_awgn_complex_baseband(x, EbN0_dB, bits_per_symbol, code_rate)
    x = x(:).';

    if nargin < 4
        code_rate = 1;
    end

    if bits_per_symbol <= 0
        error("bits_per_symbol debe ser positivo.");
    end

    if code_rate <= 0 || code_rate > 1
        error("code_rate debe estar en el intervalo (0,1].");
    end

    EbN0_linear = 10^(EbN0_dB / 10);

    Es = mean(abs(x).^2);
    Eb = Es / (bits_per_symbol * code_rate);
    N0 = Eb / EbN0_linear;

    noise_sigma = sqrt(N0 / 2);

    noise = noise_sigma * (randn(size(x)) + 1j * randn(size(x)));

    y = x + noise;
end