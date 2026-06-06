function received_symbols = demodulate_passband_qam_symbols(rx_signal, samples_per_symbol, carrier_cycles_per_symbol)
    rx_signal = rx_signal(:).';

    if mod(length(rx_signal), samples_per_symbol) ~= 0
        error("La señal recibida no es múltiplo de samples_per_symbol.");
    end

    n = 0:samples_per_symbol-1;

    phi_i = sqrt(2 / samples_per_symbol) * ...
        cos(2*pi*carrier_cycles_per_symbol*n/samples_per_symbol);

    phi_q = -sqrt(2 / samples_per_symbol) * ...
        sin(2*pi*carrier_cycles_per_symbol*n/samples_per_symbol);

    rx_matrix = reshape(rx_signal, samples_per_symbol, []).';

    i_hat = rx_matrix * phi_i.';
    q_hat = rx_matrix * phi_q.';

    received_symbols = i_hat.' + 1j*q_hat.';
end