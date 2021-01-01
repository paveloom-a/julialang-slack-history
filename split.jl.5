# This script splits the main history file to
# the portions of messages, updating the cursors

using JSON3

const messages_dir = joinpath(@__DIR__, "messages")

# For every channel
for dir in readdir(messages_dir, join=true)

    # Prepare an empty object to store the messages
    history = JSON3.Object()

    # Prepare an empty object to store the portions
    portion = JSON3.Object()

    # Get the path to the main history file
    main_file_path = joinpath(dir, "0.json")

    # Read the history inside the main file
    history = open(main_file_path, "r") do io
         JSON3.read(io)
    end

    # Get the cursor
    cursor = history[:cursor]

    # Get the messages
    messages = history[:messages]

    # Get the number of messages
    num = length(messages)

    # Get the remainder
    rem = mod(num, 100)

    # Guarantee that there will be at least
    # 50 messages in the main history file
    if num > 100 && rem ≥ 50

        # For every portion of 100 messages
        for i in 1:fld(length(messages), 100)
            portion = messages[1+100*(i-1):i*100]

            # Spit it out to a separate file
            open(joinpath(dir, "$(cursor+1).json"), "w") do io
                print(
                    io,
                    "{\"cursor\": $(cursor), \"messages\": ",
                    JSON3.write(portion),
                    '}'
                )
            end

            # And update the cursor
            cursor += 1
        end

        # Update the main history file
        open(main_file_path, "w") do io
            print(
                io,
                "{\"cursor\": $(cursor), \"messages\": ",
                JSON3.write(messages[end-rem+1:end]),
                '}'
            )
        end

    end
end
