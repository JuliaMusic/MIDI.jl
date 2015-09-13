Midi
====

A basic library for reading and writing midi files. Not currently in a complete or especially useful state. I'm working on it...

This is my first major Julia project, and is likely not idiomatic. Pull requests and suggestions are more than welcome.

Usage
=====

Opening and writing a midi file:
--------------------------------

```
midifile = readmidifile("test.mid")
writemidifile("filename.mid", midifile)
```

Creating a new file with arbitrary notes
----------------------------------------

```
# Arguments are pitch, duration (in ticks), position in track (in ticks), and velocity (0-127)
C = Midi.Note(60, 96, 0, 0)
E = Midi.Note(64, 96, 48, 0)
G = Midi.Note(67, 96, 96, 0)

inc = 96
file = Midi.MIDIFile()
track = Midi.MIDITrack()
notes = Midi.Note[]
i = 0
for v in values(Midi.GM) # GM is a map of all the general midi instrument names and their codes
    push!(notes, C)
    push!(notes, E)
    push!(notes, G)
    # This changes the instrument currently used
    Midi.programchange(track, G.position + inc + inc, uint8(0), v)
    C.position += inc
    E.position += inc
    G.position += inc
    C = Midi.Note(60, 96, C.position+inc, 0)
    E = Midi.Note(64, 96, E.position+inc, 0)
    G = Midi.Note(67, 96, G.position+inc, 0)
    i += 1
end

Midi.addnotes(track, notes)
push!(file.tracks, track)
Midi.writemidifile("test_out.mid", file)
```

Data structures and functions you should know
=============================================

```
type MIDIFile
    format::Uint16 # The format of the file. Can be 0, 1 or 2
    timedivision::Int16 # The time division of the track in ticks per beat.
    tracks::Array{MIDITrack, 1}

    MIDIFile() = new(0,96,MIDITrack[])
end
```

`function readmidifile(filename::String)` Reads a file into a MIDIFile data type

`function writemidifile(filename::String, data::MIDIFile)` Writes a midi file to the given filename

```
type MIDITrack
    events::Array{TrackEvent, 1}

    MIDITrack() = new(TrackEvent[])
    MIDITrack(events) = new(events)
end
```
