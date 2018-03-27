# MIDI.jl

A basic library for reading and writing MIDI data. Pull requests and suggestions are more than welcome. If you feel the API is clumsy or incomplete, please open an Issue about it.

| [**Package Evaluator**](http://pkg.julialang.org/?pkg=DynamicalBilliards#DynamicalBilliards) | **Travis**     | **AppVeyor** |
|:-------------------:|:-----------------------:|:-----:|
|[![](http://pkg.julialang.org/badges/DynamicalBilliards_0.6.svg)](http://pkg.julialang.org/?pkg=MIDI) | [![Build Status](https://travis-ci.org/JoelHobson/MIDI.jl.svg?branch=master)](https://travis-ci.org/JoelHobson/MIDI.jl) | [![Build status](https://ci.appveyor.com/api/projects/status/1a0ufac7gwessevh/branch/master?svg=true)](https://ci.appveyor.com/project/JuliaDynamics/midi-jl/branch/master)

---

# MIDI: The least you need to know

A MIDI file typically comes in pieces called tracks that play simultaneously. Each track can have 16 different channels, numbered 0-15. Each channel can be thought of as a single instrument, though that instrument can be changed throughout that track. A track contains events. The three types of events are MIDI events, meta events, and system exclusive (SYSEX) events.

All events begin with the time since the last event (dT) in ticks. The number of ticks per quarter note is given by the `tpq` of the midi file, `MIDIFile.tpq`. To make manipulating events easier, there's an `addevent!(track::MIDITrack, time::Integer, newevent::TrackEvent)` function specified that lets you specify absolute time (in ticks).

MIDI events handle things related to the sound, such as playing a note or moving the pitchwheel. There are constants in constants.jl to assist in creating these.

Meta events take care of things like adding copyright text or authorship information.

Sysex events are used to transmit arbitrary data. Their contents depend on the intended recipient.

---

# API

## Basic types
```julia
type MIDIFile
    format::UInt16 # The format of the file. Can be 0, 1 or 2
    tpq::Int16 # The time division of the track in ticks per beat.
    tracks::Array{MIDITrack, 1}
end

type MIDITrack
    events::Array{TrackEvent, 1}
end
```

```julia
type Note
    value::UInt8
    duration::UInt
    position::UInt
    channel::UInt8
    velocity::UInt8
end
```
Value is a number indicating pitch class & octave (middle-C is 60). Position is an absolute time (in ticks) within the track. Please note that velocity cannot be higher than 127 (0x7F). Integers can be added to, or subtracted from notes to change the pitch, and notes can be directly compared with ==. Constants exist for the different pitch values at octave 0. MIDI.C, MIDI.Cs, MIDI.Db, etc. Enharmonic note constants exist as well (MIDI.Fb). Just add 12*n to the note to transpose to octave n.

```julia
mutable struct Note{N<:AbstractNote}
    notes::Vector{N}
    tpq::Int16
end
```
`Notes` is a container of `Note`. It is iterated and accessed exactly like
the contained `Vector{Note}`. The reason that `tpq` is also bundled here
is that it allows one to obtain the note position within a bar, making
working with notes easier.

```julia
type MIDIEvent <: TrackEvent
    dT::Int
    status::UInt8
    data::Array{UInt8,1}
end

type MetaEvent <: TrackEvent
    dT::Int
    metatype::UInt8
    data::Array{UInt8,1}
end

type SysexEvent <: TrackEvent
    dT::Int
    data::Array{UInt8,1}
end
```

## Functions
The exported functions have documentation strings. Read those for proper use. This
section simply summarizes the exported content of MIDI.jl.

### Opening and writing a MIDI file
```julia
midi = readMIDIfile("test.mid") #Reads a file into a MIDIFile data type
writeMIDIfile("filename.mid", midi) #Writes a MIDI file to the given filename
```

### Utility functions
```julia
BPM(midi)
ms_per_tick(midi)
```

### Manipulating tracks
```julia
addnote!(track::MIDITrack, note::Note) # Adds a note to a track
addnotes!(track::MIDITrack, notes) # Adds a series of notes to a track

# Gets all of the notes on a track:
getnotes(midi::MIDIFile, trackno = 2)
getnotes(track::MIDITrack, tpq = 960)

# Change the program (instrument) on the given channel.
# Time is ABSOLUTE, not relative to the last event.
programchange(track::MIDITrack, time::Integer, channel::UInt8, program::UInt8)

# Add custom event (again, time is absolute)
addevent!(track::MIDITrack, time::Integer, newevent::TrackEvent)
```
`getnotes` returns `Notes` type.

---

# Example Creating a new file with arbitrary notes

```julia
using MIDI
C = Note(60, 96, 0, 0)
E = Note(64, 96, 48, 0)
G = Note(67, 96, 96, 0)

inc = 96
file = MIDIFile()
track = MIDITrack()
notes = Notes()
i = 0
# GM is a map of all the general MIDI instrument names and their codes
for v in values(MIDI.GM)
    push!(notes, C)
    push!(notes, E)
    push!(notes, G)
    # This changes the instrument currently used
    MIDI.programchange(track, G.position + inc + inc, UInt8(0), v)
    C.position += inc
    E.position += inc
    G.position += inc
    C = Note(60, 96, C.position+inc, 0)
    E = Note(64, 96, E.position+inc, 0)
    G = Note(67, 96, G.position+inc, 0)
    i += 1
end

addnotes!(track, notes)
push!(file.tracks, track)
writeMIDIfile("test_out.mid", file)
```

MIDI notes are indicated by numbers. You can use the chart below for reference. To get the number for a specific note, multiply 12 by the
octave number, and add it to one of the following
- C  = 0
- C# = 1
- Db = 1
- D  = 2
- D# = 3
- Eb = 3
- E  = 4
- F  = 5
- F# = 6
- Gb = 6
- G  = 7
- G# = 8
- Ab = 8
- A  = 9
- A# = 10
- Bb = 10
- B  = 11
- Cb = 11

For example, to find C5, you would multiply 12 * 5 and add the number for C, which is 0 in this case. So C5 is 60.

E4 = 12 * 4 + 4 = 52, D6 = 12 * 6 + 2 = 74 etc.


If you want to do more than just add notes to a track and change the program, you'll need to create the events yourself.\\ Generally, you won't want to set dT yourself. Just use `addevent!(track::MIDITrack, time::Integer, newevent::TrackEvent)` instead, and give it an absolute time within the track.

Some constants for MIDI events and program changes have been provided in constants.jl. Have fun!
