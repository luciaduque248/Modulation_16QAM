function bits = generate_bits(Nbits)
% GENERATE_BITS
% Genera una secuencia binaria.

    if nargin ~= 1
        error('generate_bits requiere exactamente un argumento: Nbits.');
    end

    if Nbits <= 0 || Nbits ~= round(Nbits)
        error('Nbits debe ser un entero positivo.');
    end

    bits = randi([0 1], Nbits, 1);
end