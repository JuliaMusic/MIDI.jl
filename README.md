MIDI
====

A basic library for reading and writing MIDI files. Not currently in a complete or especially useful state. I'm working on it...

This is my first major Julia project, and is likely not idiomatic. It's also probably quite buggy. Pull requests and suggestions are more than welcome. If you feel the API is clumsy or incomplete, please create a feature request.

MIDI: The least you need to know
================================

A MIDI file typically comes in pieces called tracks that play simultaneously. Each track can have 16 different channels, numbered 0-15. Each channel can be thought of as a single instrument, though that instrument can be changed throughout that track. A track contains events. The three types of events are MIDI events, meta events, and system exclusive (SYSEX) events.

All events begin with the time since the last event (dT) in ticks. The number of ticks per beat is given by the timedivision of the file. To make manipulating events easier, there's an `addevent(track::MIDITrack, time::Integer, newevent::TrackEvent)` function specified that lets you specify absolute time (in ticks).

MIDI events handle things related to the sound, such as playing a note or moving the pitchwheel. There are constants in constants.jl to assist in creating these.

Meta events take care of things like adding copyright text or authorship information.

Sysex events are used to transmit arbitrary data. Their contents depend on the intended recipient.

Usage
=====

Opening and writing a MIDI file:
--------------------------------

```
MIDIfile = readMIDIfile("test.mid")
writeMIDIfile("filename.mid", MIDIfile)
```

Creating a new file with arbitrary notes
----------------------------------------

```
# Arguments are pitch, duration (in ticks), position in track (in ticks), and velocity (0-127)
C = MIDI.Note(60, 96, 0, 0)
E = MIDI.Note(64, 96, 48, 0)
G = MIDI.Note(67, 96, 96, 0)

inc = 96
file = MIDI.MIDIFile()
track = MIDI.MIDITrack()
notes = MIDI.Note[]
i = 0
for v in values(MIDI.GM) # GM is a map of all the general MIDI instrument names and their codes
    push!(notes, C)
    push!(notes, E)
    push!(notes, G)
    # This changes the instrument currently used
    MIDI.programchange(track, G.position + inc + inc, uint8(0), v)
    C.position += inc
    E.position += inc
    G.position += inc
    C = MIDI.Note(60, 96, C.position+inc, 0)
    E = MIDI.Note(64, 96, E.position+inc, 0)
    G = MIDI.Note(67, 96, G.position+inc, 0)
    i += 1
end

MIDI.addnotes(track, notes)
push!(file.tracks, track)
MIDI.writeMIDIfile("test_out.mid", file)
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

`function readMIDIfile(filename::String)` Reads a file into a MIDIFile data type

`function writeMIDIfile(filename::String, data::MIDIFile)` Writes a MIDI file to the given filename

```
type MIDITrack
    events::Array{TrackEvent, 1}

    MIDITrack() = new(TrackEvent[])
    MIDITrack(events) = new(events)
end
```

`function addnote(track::MIDITrack, note::Note)` Adds a note to a track

`function addnotes(track::MIDITrack, notes::Array{Note, 1})` Adds a series of notes to a track

`function getnotes(track::MIDITrack)` Gets all of the notes on a track

`function programchange(track::MIDITrack, time::Integer, channel::Uint8, program::Uint8)` Change the program (instrument) on the given channel. Time is absolute, not relative to the last event.

```
type Note
    value::Uint8
    duration::Uint64
    position::Uint64
    channel::Uint8
    velocity::Uint8

    Note(value, duration, position, channel, velocity=0x7F)
end
```

Value is a number indicating pitch class & octave (middle-C is 60). Position is an absolute time (in ticks) within the track. Please note that velocity cannot be higher than 127 (0x7F). Integers can be added to, or subtracted from notes to change the pitch, and notes can be directly compared with ==. Constants exist for the different pitch values at octave 0. MIDI.C, MIDI.Cs, MIDI.Db, etc. Enharmonic note constants exist as well (MIDI.Fb). Just add 12*n to the note to transpose to octave n.

```
type MIDIEvent <: TrackEvent
    dT::Int
    status::Uint8
    data::Array{Uint8,1}
end

type MetaEvent <: TrackEvent
    dT::Int
    metatype::Uint8
    data::Array{Uint8,1}
end

type SysexEvent <: TrackEvent
    dT::Int
    data::Array{Uint8,1}
end
```

If you want to do more than just add notes to a track and change the program, you'll need to create the events yourself.\\ Generally, you won't want to set dT yourself. Just use `function addevent(track::MIDITrack, time::Integer, newevent::TrackEvent)` instead, and give it an absolute time within the track.

Some constants for events have been provided in constants.jl. Please take a look.
