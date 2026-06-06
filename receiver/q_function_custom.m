function y = q_function_custom(x)
    y = 0.5 * erfc(x ./ sqrt(2));
end