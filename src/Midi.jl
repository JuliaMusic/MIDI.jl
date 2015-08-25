module Midi

include("constants.jl")
include("types.jl")
include("util.jl")

export readmidi, writemidi

function readmidifile(filename::String)
    f = open(filename)

    midifile = MIDIFile()
    # Check that it's a valid midi file - first four bytes should spell MThd
    mthd = join(map(char, read(f, Uint8, 4)))
    if mthd != MTHD
        error("Not a valid midi file. Expected first 4 bytes to spell 'MThd', got $(mthd)")
    end

    # Skip the next four bytes - this is the header size, and it's always equal to 6.
    skip(f, 4)

    # Read the format code. 0 = single track, 1 = multiple tracks, 2 = multiple songs
    # Remember - midi files store data in big-endian format, which is why ntoh is used
    midifile.format = ntoh(read(f, Uint16))

    # Get the number of tracks and time division
    numberoftracks = ntoh(read(f, Uint16))

    # TODO: Handle negative values. Relates to SMPTE
    midifile.timedivision = ntoh(read(f, Uint16))

    for tracknum = [1:numberoftracks]
        track = readtrack(f)
        push!(midifile.tracks, track)
    end
    close(f)

    midifile
end

function writemidifile(filename::String, data::MIDIFile)
    f = open(filename, "w")

    write(f, convert(Array{Uint8, 1}, MTHD)) # File identifier
    write(f, hton(convert(Uint32, 6))) # Header length
    write(f, hton(data.format))
    write(f, hton(convert(Uint16, length(data.tracks))))
    write(f, hton(data.timedivision))

    for track in data.tracks
        writetrack(f, track)
    end

    close(f)
end

end
