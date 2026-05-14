function ber = compute_ber(bitsTx, bitsRx)
% COMPUTE_BER
% Calcula la tasa de error de bit:
%
%   BER = número de bits errados / número de bits transmitidos

    bitsTx = bitsTx(:);
    bitsRx = bitsRx(:);

    if isempty(bitsTx)
        error('bitsTx está vacío.');
    end

    if isempty(bitsRx)
        error('bitsRx está vacío.');
    end

    if length(bitsTx) ~= length(bitsRx)
        error('bitsTx y bitsRx deben tener la misma longitud.');
    end

    if any(bitsTx ~= 0 & bitsTx ~= 1)
        error('bitsTx debe contener únicamente bits 0 o 1.');
    end

    if any(bitsRx ~= 0 & bitsRx ~= 1)
        error('bitsRx debe contener únicamente bits 0 o 1.');
    end

    bitErrors = sum(bitsTx ~= bitsRx);

    ber = bitErrors / length(bitsTx);
end