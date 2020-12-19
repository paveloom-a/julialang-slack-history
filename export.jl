# This is a script to export Slack history from
# Julia's Slack (https://julialang.slack.com/)

# Note that the script is supposed to run as a step in a CI job, and it
# expects a Slack's user token provided in a `TOKEN` environment variable

using HTTP
using JSON3

# Headers
headers = ["Content-Type" => "application/x-www-form-urlencoded"]

# Endpoints
base = "https://slack.com/api"
conversations = base * "/conversations"
conversations_list = conversations * ".list"
conversations_history = conversations * ".history"

# Error messages

no_token_error = "\n
There is no `TOKEN` environment variable provided, aborting.
Note that a token that starts with `xoxs-` is expected.\n"

request_failed(endpoint) = "\n
The request to the \"$(endpoint)\" endpoint got rejected. Maybe an invalid token?\n"

# Create a request to the endpoint and return the body
function request(endpoint, query)
    request = HTTP.get(endpoint, headers; query)
    body = JSON3.read(String(request.body))
    (request.status ≠ 200 || body[:ok] == false) && (error(request_failed(endpoint)))
    return body
end

# Pack the arguments in a dictionary using their names as keys
macro query(args::Symbol...)
    return esc(
        Expr(:call, :Dict, Expr(:tuple, Expr.(:call, :(=>), QuoteNode.(args), args)...))
    )
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

# Get and save the history of every channel
for channel in channels

    # Create a directory for the channel (if doesn't exist)
    channel_path = mkpath(joinpath(@__DIR__, "channels", channel[:name]))

    # Get the paths to the JSON files of the channel
    messages_path = joinpath(channel_path, "messages.json")
    threads_path = joinpath(channel_path, "threads.json")

    # Get the ID of the channel
    channel = channel[:id]

    # Extract the history from all pages

    history = request(conversations_history, @query(channel, token))
    open(messages_path, "a") do io
        JSON3.write(io, history[:messages])
    end

    while get(history, :has_more, false)

        cursor = history[:response_metadata][:next_cursor]
        history = request(conversations_history, @query(channel, cursor, token))
        open(messages_path, "a") do io
            JSON3.write(io, history[:messages])
        end

    end

end
