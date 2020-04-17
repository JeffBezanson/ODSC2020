using Zygote

## Simple gradients

gradient(x->x^2, 3)

## Gradients of ... what?!

fs = Dict("sin" => sin, "cos" => cos, "tan" => tan);

gradient(x -> fs[readline()](x), 1)
