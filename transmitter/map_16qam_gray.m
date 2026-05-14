function [symbols, mapInfo] = map_16qam_gray(bits, p)
% MAP_16QAM_GRAY
% Agrupa bits y los convierte en símbolos 16-QAM Gray.
%
% Cada símbolo 16-QAM representa:
%   k = log2(16) = 4 bits
%
% Separación:
%   bits 1 y 2 -> componente en fase I
%   bits 3 y 4 -> componente en cuadratura Q
%
% Mapeo Gray 4-PAM por dimensión:
%   00 -> -3
%   01 -> -1
%   11 ->  1
%   10 ->  3
%
% Luego se normaliza por 1/sqrt(10) para que Es = 1.

    bits = bits(:);

    if p.M ~= 16
        error('map_16qam_gray está diseñado únicamente para M = 16.');
    end

    if mod(length(bits), p.k) ~= 0
        error('La cantidad de bits debe ser múltiplo de log2(M).');
    end

    bitGroups = reshape(bits, p.k, []).';

    bitsI = bitGroups(:, 1:2);
    bitsQ = bitGroups(:, 3:4);

    I = gray_pair_to_pam4_level(bitsI);
    Q = gray_pair_to_pam4_level(bitsQ);

    symbols = (I + 1j*Q) * p.constellationScale;

    % Construcción de la constelación ideal completa con el mismo mapeo.
    grayPairs = [
        0 0
        0 1
        1 1
        1 0
    ];

    levels = gray_pair_to_pam4_level(grayPairs) * p.constellationScale;

    constellation = zeros(16, 1);
    labels = zeros(16, 4);

    idx = 1;
    for ii = 1:4
        for qq = 1:4
            constellation(idx) = levels(ii) + 1j*levels(qq);
            labels(idx, :) = [grayPairs(ii, :) grayPairs(qq, :)];
            idx = idx + 1;
        end
    end

    mapInfo.constellation = constellation;
    mapInfo.labels = labels;
    mapInfo.levels = levels;
    mapInfo.unscaledLevels = [-3; -1; 1; 3];
    mapInfo.scale = p.constellationScale;
    mapInfo.EsEstimated = mean(abs(constellation).^2);
end

function levels = gray_pair_to_pam4_level(twoBits)
% GRAY_PAIR_TO_PAM4_LEVEL
% Convierte pares de bits Gray a niveles 4-PAM.

    if size(twoBits, 2) ~= 2
        error('La entrada debe tener dos columnas.');
    end

    N = size(twoBits, 1);
    levels = zeros(N, 1);

    for n = 1:N
        b1 = twoBits(n, 1);
        b2 = twoBits(n, 2);

        if b1 == 0 && b2 == 0
            levels(n) = -3;
        elseif b1 == 0 && b2 == 1
            levels(n) = -1;
        elseif b1 == 1 && b2 == 1
            levels(n) = 1;
        elseif b1 == 1 && b2 == 0
            levels(n) = 3;
        else
            error('Los bits solo pueden ser 0 o 1.');
        end
    end
end