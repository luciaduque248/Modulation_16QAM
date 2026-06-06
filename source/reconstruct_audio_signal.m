function x_rec = reconstruct_audio_signal(indices, levels)
    indices = indices(:);

    if any(indices < 0) || any(indices > length(levels)-1)
        error("Índices fuera del rango de niveles de cuantificación.");
    end

    x_rec = levels(indices + 1).';
    x_rec = x_rec(:);
end