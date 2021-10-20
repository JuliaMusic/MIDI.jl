# This file extends the FileIO.jl interface for filenames ending with ".mid".
# See https://juliaio.github.io/FileIO.jl/stable/implementing/#Implementing-loaders/savers

using FileIO
export load, save

function fileio_load(f::File{format"MIDI"})
    open(f) do s
        skipmagic(s)
        midifile = load(s)
    end
end

function fileio_load(s::Stream{format"MIDI"})
    midifile = MIDIFile()

    # Skip the next four bytes - this is the header size, and it's always equal to 6.
    skip(s, 4)

    # Read the format code. 0 = single track, 1 = multiple tracks, 2 = multiple songs
    # Remember - MIDI files store data in big-endian format, which is why ntoh is used
    midifile.format = ntoh(read(s, UInt16))

    # Get the number of tracks and time division
    numberoftracks = ntoh(read(s, UInt16))
    midifile.tpq = ntoh(read(s, Int16))
    midifile.tracks = [readtrack(s.io) for x in 1:numberoftracks]

    return midifile
end

function fileio_save(f::File{format"MIDI"}, data::MIDIFile)
    open(f, "w") do s
        fileio_save(s, data)
    end
end

function fileio_save(s::Stream{format"MIDI"}, data::MIDIFile)
    write(s, magic(format"MIDI"))

    write(s, hton(convert(UInt32, 6))) # Header length
    write(s, hton(data.format))
    write(s, hton(convert(UInt16, length(data.tracks))))
    write(s, hton(data.tpq))

    map(track -> writetrack(s.io, track), data.tracks)
    return data
end

function fileio_save(s::Union{File{format"MIDI"}, Stream{format"MIDI"}}, notes::Notes)
    track = MIDITrack()
    addnotes!(track, notes)
    midi = MIDIFile(1, notes.tpq, [track])
    fileio_save(s, midi)
    return midi
end
