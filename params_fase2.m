function cfg = params_fase2()
    cfg.audio_path = "audio/mi_audio.wav";
    cfg.output_dir = "output";

    cfg.min_duration_s = 10;
    cfg.n_bits_audio = 8;

    cfg.M = 16;
    cfg.bits_per_symbol = log2(cfg.M);

    cfg.code_rate = 4/7;

    cfg.EbN0_single_dB = 12;
    cfg.EbN0_dB_vector = 0:2:16;

    cfg.max_bits_for_ber = 500000;
    cfg.max_bits_passband = 120000;

    cfg.samples_per_symbol = 16;
    cfg.carrier_cycles_per_symbol = 2;

    cfg.random_seed = 1;
    cfg.save_figures = true;
end