type MIDIFile
    format::UInt16 # The format of the file. Can be 0, 1 or 2
    timedivision::Int16 # The time division of the track. Ticks per beat.
    tracks::Array{MIDITrack, 1} # An array of tracks

    MIDIFile() = new(0,96,MIDITrack[])
end

# Reads a file into a MIDIFile data type
function readMIDIfile(filename::AbstractString)
    f = open(filename)

    MIDIfile = MIDIFile()
    # Check that it's a valid MIDI file - first four bytes should spell MThd
    mthd = join(map(Char, read(f, UInt8, 4)))
    if mthd != MTHD
        error("Not a valid MIDI file. Expected first 4 bytes to spell 'MThd', got $(mthd)")
    end

    # Skip the next four bytes - this is the header size, and it's always equal to 6.
    skip(f, 4)

    # Read the format code. 0 = single track, 1 = multiple tracks, 2 = multiple songs
    # Remember - MIDI files store data in big-endian format, which is why ntoh is used
    MIDIfile.format = ntoh(read(f, UInt16))

    # Get the number of tracks and time division
    numberoftracks = ntoh(read(f, UInt16))
    MIDIfile.timedivision = ntoh(read(f, Int16))
    MIDIfile.tracks = [readtrack(f) for x in 1:numberoftracks]
    close(f)

    MIDIfile
end

# Writes a MIDI file to the given filename
function writeMIDIfile(filename::AbstractString, data::MIDIFile)
    f = open(filename, "w")

    write(f, convert(Array{UInt8, 1}, MTHD)) # File identifier
    write(f, hton(convert(UInt32, 6))) # Header length
    write(f, hton(data.format))
    write(f, hton(convert(UInt16, length(data.tracks))))
    write(f, hton(data.timedivision))

    map(track->writetrack(f, track), data.tracks)

    close(f)
end

export MIDIFile, readMIDIfile, writeMIDIfile
