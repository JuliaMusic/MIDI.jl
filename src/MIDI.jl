"""
A Julia library for reading and writing MIDI files.
"""
module MIDI

using Base.Unicode

include("constants.jl")
include("note.jl")
include("trackevent.jl")
include("events.jl")
include("miditrack.jl")
include("midifile.jl")
include("io.jl")
include("variablelength.jl")
include("convert.jl")
include("findevents.jl")
include("deprecations.jl")

export testmidi, testnotes
export DRUMKEY
export type1totype0, type1totype0!
export type0totype1, type0totype1!
export getprogramchangeevents
export encode
export trackname, addtrackname!, findtextevents
export tracknames
export MIDIFile, readMIDIFile, writeMIDIFile
export BPM, bpm, qpm, time_signature, tempochanges, ms_per_tick
export getnotes, addnote!, addnotes!, addevent!, addevents!
export MIDITrack
export Note, Notes, AbstractNote, DrumNote
export pitch_to_name, name_to_pitch, is_octave
export pitch_to_hz, hz_to_pitch
export TrackEvent, MetaEvent, MIDIEvent, SysexEvent
export readvariablelength, writevariablelength

"""
    testmidi()
Return the path to a test MIDI file.
"""
testmidi() = joinpath(dirname(@__DIR__), "test", "doxy.mid")

"""
    testnotes()
Return a test set of human-played MIDI notes on the piano.
"""
testnotes() = getnotes(readMIDIFile(testmidi()), 4)

end
