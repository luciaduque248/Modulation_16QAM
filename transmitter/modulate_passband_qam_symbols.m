function tx_signal = modulate_passband_qam_symbols(symbols, samples_per_symbol, carrier_cycles_per_symbol)
    symbols = symbols(:).';

    if samples_per_symbol <= 0 || mod(samples_per_symbol, 1) ~= 0
        error("samples_per_symbol debe ser un entero positivo.");
    end

    if carrier_cycles_per_symbol <= 0 || mod(carrier_cycles_per_symbol, 1) ~= 0
        error("carrier_cycles_per_symbol debe ser un entero positivo.");
    end

    n = 0:samples_per_symbol-1;

    phi_i = sqrt(2 / samples_per_symbol) * ...
        cos(2*pi*carrier_cycles_per_symbol*n/samples_per_symbol);

    phi_q = -sqrt(2 / samples_per_symbol) * ...
        sin(2*pi*carrier_cycles_per_symbol*n/samples_per_symbol);

    tx_matrix = real(symbols).' * phi_i + imag(symbols).' * phi_q;

    tx_signal = reshape(tx_matrix.', 1, []);
end