function y = q_function_custom(x)

    N = 10000;      % Número de intervalos
    xmax = 10;      % Aproximación del infinito

    t = linspace(x, xmax, N);

    f = (1/sqrt(2*pi))*exp(-(t.^2)/2);

    h = (xmax - x)/(N-1);

    y = h*(0.5*f(1) + sum(f(2:end-1)) + 0.5*f(end));

end