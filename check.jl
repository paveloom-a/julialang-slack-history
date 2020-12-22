# This is a script to check if the
# history exported from the Julia's Slack
# (https://julialang.slack.com/) is parsable

using JSON3
using Test

const messages_dir = joinpath(@__DIR__, "messages")
const threads_dir = joinpath(@__DIR__, "threads")

@testset "Messages" begin
    for file in readdir(messages_dir, join=true)
        open(file, "r") do io
            try
                @test_nowarn JSON3.read(io)
            catch
                println("\n\e[1;31mWhoops! File: $(basename(file))\e[0m\n")
                rethrow()
            end
        end
    end
end

@testset "Threads" begin
    for dir in readdir(threads_dir, join=true)
        for file in readdir(dir, join=true)
            open(file, "r") do io
                try
                    @test_nowarn JSON3.read(io)
                catch
                    println("\n\e[1;31mWhoops! File: $(dir)/$(basename(file))\e[0m\n")
                    rethrow()
                end
            end
        end
    end
end
