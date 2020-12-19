# This is a script to export Slack history from
# Julia's Slack (https://julialang.slack.com/)

# Note that the script is supposed to run as a step in a CI job, and it
# expects a Slack's user token provided in a `TOKEN` environment variable

using HTTP
using JSON3
using ProgressMeter

# Headers
const headers = ["Content-Type" => "application/x-www-form-urlencoded"]

# Endpoints
const base = "https://slack.com/api"
const conversations = base * "/conversations"
const conversations_list = conversations * ".list"
const conversations_history = conversations * ".history"
const conversations_replies = conversations * ".replies"

# Error messages

const no_token_error = "\n
There is no `TOKEN` environment variable provided, aborting.
Note that a token that starts with `xoxs-` is expected.\n"

request_failed(endpoint) = "\n
The request to the \"$(endpoint)\" endpoint got rejected.\n
Maybe an invalid token? Or a rate limit exceeded?\n"

# Pack the arguments in a dictionary using their names as keys
macro query(args::Symbol...)
    return esc(
        Expr(:call, :Dict, Expr(:tuple, Expr.(:call, :(=>), QuoteNode.(args), args)...))
    )
end

# Create a request to the endpoint and return the body
function request(endpoint, query)
    try
        request = HTTP.get(endpoint, headers; query)
        body = JSON3.read(String(request.body))
        (request.status ≠ 200 || body[:ok] == false) && error("`ok` check failed.")
        return body
    catch
        error(request_failed(endpoint))
    end
end

# Get a user token from the `TOKEN` environment variable
token = get(ENV, "TOKEN") do
    error(no_token_error)
end

# Set a limit for pagination
limit = 1000

# Get a list of channels
channels = request(conversations_list, @query(limit, token))[:channels]

# Filter out archived channels
channels = filter(ch -> !ch[:is_archived], channels)

# Write the channels summary
open(joinpath(@__DIR__, "channels.json"), "w") do io
    JSON3.write(io, Dict(getindex.(channels, :id) .=> getindex.(channels, :name)))
end

# Create directories for messages and threads (if they don't exist)
const messages_dir = mkpath(joinpath(@__DIR__, "messages"))
const threads_dir = mkpath(joinpath(@__DIR__, "threads"))

# Write a thread
function write_thread(replies, threads_path; comma=false)
    open(threads_path, "a") do io
        if comma
            print(io, "," * chop(JSON3.write(replies), head=1))
        else
            print(io, chop(JSON3.write(replies), head=1))
        end
    end
end

# Write the messages and threads
function write(channel, history, messages_path; comma=false)

    # Get the messages
    messages = history[:messages]

    # Write the messages
    open(messages_path, "a") do io
        if comma
            print(io, "," * chop(JSON3.write(messages), head=1))
        else
            print(io, chop(JSON3.write(messages), head=1))
        end
    end

    # Write the threads
    for ts in filter(!isempty, get.(messages, :thread_ts, ""))

        # Set the path to the output file for the thread
        threads_path = joinpath(threads_dir, "$(ts).json")

        # Write the first bracket
        open(threads_path, "w") do io
            print(io, '[')
        end

        # Write the first portion of the thread
        replies = request(conversations_replies, @query(channel, token, ts))
        write_thread(replies, threads_path)

        # Write the next portions of the thread
        while get(replies, :has_more, false)
            cursor = replies[:response_metadata][:next_cursor]
            replies = request(conversations_replies, @query(channel, cursor, token, ts))
            write_thread(replies, threads_path, comma=true)
        end

        # Write the last bracket
        open(threads_path, "a") do io
            print(io, ']')
        end

    end

end

# Get and save the history of every channel
@showprogress 1 "Exporting..." for channel in getindex.(channels, :id)

    # Set the path to the output file for the channel
    messages_path = joinpath(messages_dir, "$(channel).json")

    # Write the first bracket
    if !isfile(messages_path) || (isfile(messages_path) && filesize(messages_path) == 0)
        open(messages_path, "w") do io
            print(io, '[')
        end
    # Or remove the last one
    else
        content = open(messages_path, "r") do io
            read(io, String)
        end
        open(messages_path, "w") do io
            print(io, chop(content) * ",")
        end
    end

    # Write the first portion of the messages history
    history = request(conversations_history, @query(channel, token))
    write(channel, history, messages_path)

    # Write the next portions of the messages history
    while get(history, :has_more, false)
        cursor = history[:response_metadata][:next_cursor]
        history = request(conversations_history, @query(channel, cursor, token))
        write(channel, history, messages_path, comma=true)
    end

    # Write the last bracket
    open(messages_path, "a") do io
        print(io, ']')
    end

end
