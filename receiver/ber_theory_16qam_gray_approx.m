function Pb = ber_theory_16qam_gray_approx(EbN0_dB, p)
% BER_THEORY_16QAM_GRAY_APPROX
% BER aproximada para 16-QAM Gray sobre AWGN.
%
% Se usa una aproximación coherente con el criterio de vecinos cercanos:
%
%   Pe ≈ k_vecinos * Q(dmin / sqrt(2*N0))
%
% Para 16-QAM cuadrada:
%
%   k_vecinos = (4 esquinas*2 + 8 bordes*3 + 4 interiores*4)/16 = 3
%
% Con codificación Gray:
%
%   Pb ≈ Pe/log2(M)

    if nargin ~= 2
        error('Debe ingresar EbN0_dB y p.');
    end

    if p.M ~= 16
        error('Esta función solo está definida para 16-QAM.');
    end

    EbN0_dB = EbN0_dB(:).';

    EbN0_linear = 10.^(EbN0_dB/10);

    Es = p.Es;
    Eb = Es / p.k;

    N0 = Eb ./ EbN0_linear;

    dmin = 2 * p.constellationScale;

    kVecinos = 3;

    Pe = kVecinos .* Q_local(dmin ./ sqrt(2 .* N0));

    Pb = Pe ./ p.k;

    Pb(Pb > 1) = 1;
    Pb(Pb < 0) = 0;
end

function q = Q_local(x)
% Q_LOCAL
% Q(x) = 0.5 erfc(x/sqrt(2))

    q = 0.5 * erfc(x ./ sqrt(2));
end