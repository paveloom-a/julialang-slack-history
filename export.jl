# This is a script to export Slack history from
# Julia's Slack (https://julialang.slack.com/)

# Note that the script is supposed to run as a step in a CI job, and it
# expects a Slack's user token provided in a `TOKEN` environment variable

using HTTP
using JSON3

# Headers
const headers = ["Content-Type" => "application/x-www-form-urlencoded"]

# ANSI escape sequences
const green = "\e[1;32m"
const yellow = "\e[1;33m"
const blue = "\e[1;34m"
const reset = "\e[0m"

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
Maybe an invalid token?\n"

# Pack the arguments in a dictionary using their names as keys
macro query(args::Symbol...)
    return esc(
        Expr(:call, :Dict, Expr(:tuple, Expr.(:call, :(=>), QuoteNode.(args), args)...))
    )
end

# Create a request to the endpoint and return the body
function request(endpoint, query, pad_length=0)
    try
        request = HTTP.get(endpoint, headers; query)
        body = JSON3.read(String(request.body))
        if (request.status ≠ 200 || body[:ok] == false)
            error("\nThe `ok` check has failed.\n")
        end
        return body
    catch e
        # Wait if the rate limit is exceeded
        if e isa HTTP.ExceptionRequest.StatusError
            println(
                ' '^(pad_length + 5),
                "$(yellow) ➥ The rate limit is exceeded. Waiting...$(reset)",
            )
            sleep(60)
            return request(endpoint, query, pad_length)
        # Or report an error
        else
            error(request_failed(endpoint))
        end
    end
end

# Get a user token from the `TOKEN` environment variable
token = get(ENV, "TOKEN") do
    error(no_token_error)
end

# Set a limit for pagination (channels)
limit = 1000

# Get a list of channels
channels = request(conversations_list, @query(limit, token))[:channels]

# Filter out archived channels
channels = filter(ch -> !ch[:is_archived], channels)

# Sort the channels by names
channels = sort(channels, by=ch -> ch[:name])

# Get the IDs
ids = getindex.(channels, :id)

# Get the names
names = getindex.(channels, :name)

# Write the channels IDs (array)
open(joinpath(@__DIR__, "channels.json"), "w") do io
    JSON3.write(io, ids)
end

# Write the channels names (dictionary)
open(joinpath(@__DIR__, "names.json"), "w") do io
    JSON3.write(io, Dict(ids .=> names))
end

# Set a limit for pagination (messages and threads)
limit = 200

# Create directories for messages and threads (if they don't exist)
const messages_dir = mkpath(joinpath(@__DIR__, "messages"))
const threads_dir = mkpath(joinpath(@__DIR__, "threads"))

# Write the messages and threads
function write(
    channel,
    history,
    pad_length,
    old_messages,
    new_messages,
)
    # Get the messages
    messages = history[:messages]

    # Get the threads timestamps
    threads = filter(!isempty, get.(messages, :thread_ts, ""))

    # Get the number of threads
    threads_num = length(threads)

    # If no old messages, write the current history
    if isempty(old_messages)
        if !isempty(messages)
            new_messages[] = [new_messages[]; messages]
        end
    # Otherwise, determine what needs to be appended
    else
        # Get the timestamps from both packs of messages
        current_timestamps = [message[:ts] for message in messages]
        old_timestamps = [message[:ts] for message in old_messages[:messages]]

        # Determine the indices of unique timestamps
        inds = findall(timestamp -> !(timestamp in old_timestamps), current_timestamps)

        # Get the unique messages
        messages = messages[inds]

        if !isempty(messages)
            new_messages[] = [new_messages[]; messages]
        end
    end

    # Create a directory for the channel in the threads folder
    threads_channel_dir = mkpath(joinpath(threads_dir, channel))

    # Write the threads
    for (index, ts) in pairs(threads)

        # Prepare an empty array of JSON objects to store new threads
        new_threads = JSON3.Object[]

        # Get a counter string
        counter = lpad("($(index)/$(threads_num))", pad_length)

        # Print the info
        println(
            ' '^5,
            "$(green)$(counter) ➥ Exporting the ",
            "$(blue)$(ts)$(green) thread...$(reset)",
        )

        # Set the path to the output file for the thread
        threads_path = joinpath(threads_channel_dir, "$(ts).json")

        # Get the first portion of the thread
        replies = request(
            conversations_replies,
            @query(channel, limit, token, ts),
            pad_length
        )
        new_threads = [new_threads; replies[:messages]]

        # Get the next portions of the thread
        while get(replies, :has_more, false)
            println(
                ' '^(pad_length + 5),
                "$(green) ➥ Taking the next portion of the thread...$(reset)",
            )
            cursor = replies[:response_metadata][:next_cursor]
            replies = request(
                conversations_replies,
                @query(channel, cursor, limit, token, ts),
                pad_length,
            )
            new_threads = [new_threads; replies[:messages]]
        end

        # Write the thread
        open(threads_path, "w") do io
            print(io, JSON3.write(new_threads))
        end

    end
end

println(
    '\n',
    ' '^5,
    "$(green)Started exporting the history of Julia's Slack ",
    "(https://julialang.slack.com).$(reset)\n"
)

# Get the number of channels
channels_num = length(ids)

# Get and save the history of every channel
for index in eachindex(ids)

    # Print the info
    println(
        ' '^5,
        "$(green)($(index)/$(channels_num)) Exporting the ",
        "$(blue)$(ids[index])$(green) ($(names[index])) channel...$(reset)",
    )

    # Get the ID of the channel
    channel = ids[index]

    # Calculate the pad length for the counters
    pad_length = length("($(index)/$(channels_num))")

    # Set the path to the output file for the channel
    messages_channel_dir = joinpath(messages_dir, channel)
    messages_path = joinpath(messages_channel_dir, "0.json")

    # Prepare an empty object to store the old messages
    old_messages = JSON3.Object()

    # Prepare a reference to an empty array of JSON objects to store new messages
    new_messages = Ref{Vector{JSON3.Object}}([])

    # If the history of the channel
    # was written before, load it and
    # rewrite, removing the first bracket
    if isfile(messages_path)
        old_messages = open(messages_path, "r") do io
            JSON3.read(io)
        end
    end

    # Write the first portion of the messages history
    history = request(conversations_history, @query(channel, limit, token), pad_length)
    write(channel, history, pad_length, old_messages, new_messages)

    # Write the next portions of the messages history
    while get(history, :has_more, false)
        println(
            ' '^(pad_length + 5),
            "$(green) ➥ Taking the next portion of messages...$(reset)"
        )
        cursor = history[:response_metadata][:next_cursor]
        history = request(
            conversations_history,
            @query(channel, cursor, limit, token),
            pad_length
        )
        write(
            channel,
            history,
            pad_length,
            old_messages,
            new_messages,
        )
    end

    # If no old messages, write the new ones
    if isempty(old_messages)
        if !isempty(new_messages[])
            mkpath(messages_channel_dir)
            open(messages_path, "w") do io
                print(
                    io,
                    "{\"cursor\": 0, \"messages\": ",
                    JSON3.write(reverse(new_messages[])),
                    "}",
                )
            end
        end
    # Otherwise, append the new messages (if there are any)
    else
        if !isempty(new_messages[])
            open(messages_path, "w") do io
                print(
                    io,
                    "{\"cursor\": $(old_messages[:cursor]), \"messages\": ",
                    chop(JSON3.write(old_messages[:messages])),
                    ',',
                    chop(JSON3.write(reverse(new_messages[])), head=1, tail=0),
                    "}",
                )
            end
        end
    end

    println()

end

println(' '^5, "$(green)Done.$(reset)\n")
