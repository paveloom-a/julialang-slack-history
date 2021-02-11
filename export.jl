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
const bots = base * "/bots"
const bots_info = bots * ".info"
const users = base * "/users"
const users_info = users * ".info"

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
function request(endpoint, headers, query, pad_length=0)
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
            return request(endpoint, headers, query, pad_length)
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
channels = request(conversations_list, headers, @query(limit, token))[:channels]

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

# Create directories for messages, threads, and users (if they don't exist)
const messages_dir = mkpath(joinpath(@__DIR__, "messages"))
const threads_dir = mkpath(joinpath(@__DIR__, "threads"))
const users_dir = mkpath(joinpath(@__DIR__, "users"))

# Write the messages, threads, and users
function write(
    channel,
    history,
    pad_length,
    old_messages,
    old_ts,
    new_messages,
)
    # Get the messages
    messages = history[:messages]

    # If no old messages, write the current history
    if isempty(old_messages)
        if !isempty(messages)
            new_messages[] = [new_messages[]; messages]
        end
    # Otherwise, determine what needs to be appended
    else
        # Get the current timestamps from the new messages
        current_ts = [message[:ts] for message in messages]

        # Determine the indices of unique IDs
        inds = findall(ts -> !(ts in old_ts), current_ts)

        # Get the unique messages
        unique_messages = messages[inds]

        # Append if found any
        if !isempty(unique_messages)
            new_messages[] = [new_messages[]; unique_messages]
        end
    end

    # Get the threads timestamps
    threads = filter(!isempty, get.(messages, :thread_ts, ""))

    # Get the number of threads
    threads_num = length(threads)

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
        thread_path = joinpath(threads_channel_dir, "$(ts).json")

        # Get the first portion of the thread
        replies = request(
            conversations_replies,
            headers,
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
                headers,
                @query(channel, cursor, limit, token, ts),
                pad_length,
            )
            new_threads = [new_threads; replies[:messages]]
        end

        # Write the thread
        open(thread_path, "w") do io
            print(io, JSON3.write(new_threads))
        end

    end

    # Get the user IDs
    message_users = filter(!isempty, get.(messages, :user, ""))
    reply_users = vcat(filter(!isempty, get.(messages, :reply_users, ""))...)
    unique_users = unique([message_users; reply_users])

    # Get the number of users
    users_num = length(unique_users)

    # Write the users
    for (index, user) in pairs(unique_users)

        # Get a counter string
        counter = lpad("($(index)/$(users_num))", pad_length)

        # Print the info
        println(
            ' '^5,
            "$(green)$(counter) ➥ Exporting the ",
            "$(blue)$(user)$(green)'s user info...$(reset)",
        )

        # Set the path to the output file for the user
        user_path = joinpath(users_dir, "$(user).json")

        # Check if the user is actually a bot
        if startswith(user, "U")

            # Get the info about the user
            info = request(
                users_info,
                headers,
                @query(token, user),
                pad_length
            )

            # Write the info
            open(user_path, "w") do io
                print(io, JSON3.write(info[:user]))
            end

        else

            # Copy the ID to another variable
            bot = user

            # Get the info about the bot
            info = request(
                bots_info,
                headers,
                @query(token, bot),
                pad_length
            )

            # Write the info
            open(user_path, "w") do io
                print(io, JSON3.write(info[:bot]))
            end

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

    # Prepare a variable to store the length
    # of the first portion of messages
    old_messages_fpl = 0

    # Prepare an empty array to store old timestamps
    old_ts = String[]

    # Prepare a reference to an empty array of JSON
    # objects to store portions of new messages
    new_messages = Ref{Vector{JSON3.Object}}([])

    # If the history of the channel
    # was written before, load it and
    # rewrite, removing the first bracket
    if isfile(messages_path)

        # Prepare an empty array of JSON objects
        # to store portions of old messages
        old_messages_portions = Vector{JSON3.Object}[]

        # Get the first portion of the old messages
        portion = open(messages_path, "r") do io
            JSON3.read(io)
        end
        old_messages_portions = [old_messages_portions; portion[:messages]]
        old_messages_fpl = length(old_messages_portions)

        # Get the cursor to the next portion
        cursor = portion[:cursor]
        i = cursor

        # Get the next portions of the old messages
        while i != 0
            path = joinpath(messages_channel_dir, "$(i).json")
            portion = open(path, "r") do io
                JSON3.read(io)
            end
            old_messages_portions = [old_messages_portions; portion[:messages]]
            i -= 1
        end

        # Combine all of the portions
        old_messages = JSON3.read(
            JSON3.write(
                Dict(:cursor => cursor, :messages => old_messages_portions)
            )
        )

        # Get old timestamps
        old_ts = [message[:ts] for message in old_messages_portions]
    end

    # Get the first portion of the messages history
    history = request(
        conversations_history,
        headers,
        @query(channel, limit, token),
        pad_length
    )
    write(channel, history, pad_length, old_messages, old_ts, new_messages)

    # Get the next portions of the messages history
    while get(history, :has_more, false)
        println(
            ' '^(pad_length + 5),
            "$(green) ➥ Taking the next portion of messages...$(reset)"
        )
        cursor = history[:response_metadata][:next_cursor]
        history = request(
            conversations_history,
            headers,
            @query(channel, cursor, limit, token),
            pad_length
        )
        write(
            channel,
            history,
            pad_length,
            old_messages,
            old_ts,
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
                    chop(JSON3.write(old_messages[:messages][1:old_messages_fpl])),
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
