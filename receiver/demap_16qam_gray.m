function bitsHat = demap_16qam_gray(rxSymbols, p)
% DEMAP_16QAM_GRAY
% Demapeo 16-QAM Gray.
%
% Cada símbolo recibido se decide por regiones independientes:
%   I -> 4-PAM Gray
%   Q -> 4-PAM Gray
%
% Niveles no normalizados:
%   -3, -1, 1, 3
%
% Umbrales:
%   -2, 0, 2

    rxSymbols = rxSymbols(:);

    if isempty(rxSymbols)
        error('rxSymbols está vacío.');
    end

    if p.M ~= 16
        error('demap_16qam_gray solo está definido para M = 16.');
    end

    rxI = real(rxSymbols) / p.constellationScale;
    rxQ = imag(rxSymbols) / p.constellationScale;

    bitsI = local_pam4_gray_decision(rxI);
    bitsQ = local_pam4_gray_decision(rxQ);

    bitGroups = [bitsI bitsQ];

    bitsHat = reshape(bitGroups.', [], 1);
end

function bits2 = local_pam4_gray_decision(x)

    x = x(:);
    N = length(x);

    bits2 = zeros(N, 2);

    for n = 1:N

        if x(n) < -2
            bits2(n, :) = [0 0];

        elseif x(n) < 0
            bits2(n, :) = [0 1];

        elseif x(n) < 2
            bits2(n, :) = [1 1];

        else
            bits2(n, :) = [1 0];

        end
    end
end