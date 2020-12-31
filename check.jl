# This is a script to check if the
# history exported from the Julia's Slack
# (https://julialang.slack.com/) is parsable

using JSON3
using Test

const messages_dir = joinpath(@__DIR__, "messages")
const threads_dir = joinpath(@__DIR__, "threads")
const users_dir = joinpath(@__DIR__, "users")

function test(target; loop_dirs=true)
    if loop_dirs
        for dir in readdir(target, join=true)
            for file in readdir(dir, join=true)
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
    else
        for file in readdir(target, join=true)
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
end

@testset "Messages" begin
    test(messages_dir)
end

@testset "Threads" begin
    test(threads_dir)
end

@testset "Users" begin
    test(users_dir, loop_dirs=false)
end
