function [x, Fs] = read_audio_source(audio_path, min_duration_s)
    if ~isfile(audio_path)
        error("No se encontró el archivo de audio: %s", audio_path);
    end

    [x, Fs] = audioread(audio_path);

    if size(x, 2) > 1
        x = mean(x, 2); % Conversión a mono
    end

    duration_s = length(x) / Fs;

    if duration_s < min_duration_s
        error("El audio dura %.2f s. Debe durar mínimo %.2f s.", duration_s, min_duration_s);
    end

    x = x(1:floor(min_duration_s * Fs));
    x = max(min(x, 1), -1);
end