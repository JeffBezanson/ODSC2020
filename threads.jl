using Images, Random
import Base.Threads: @threads, @spawn

function escapetime(z; maxiter=80)
    c = z
    for n = 1:maxiter
        if abs(z) > 2
            return n-1
        end
        z = z^2 + c
    end
    return maxiter
end

function mandel(; width=80, height=20, maxiter=80)
    out = zeros(Int, height, width)
    real = range(-2.0, 0.5, length=width)
    imag = range(-1.0, 1.0, length=height)
    for x in 1:width
        for y in 1:height
            z = real[x] + imag[y]*im
            out[y,x] = escapetime(z, maxiter=maxiter)
        end
    end
    return out
end

@time m = mandel(width=1200,height=900,maxiter=400)
Gray.(m./80)

## CSV parsing

using CSV, BenchmarkTools

run(`python3 -m timeit -s "import pandas" -p "pandas.read_csv('mixed.csv')"`)

@btime CSV.read("mixed.csv", threaded=false)

@btime CSV.read("mixed.csv", threaded=true)
