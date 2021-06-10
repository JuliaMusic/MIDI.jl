export MIDIFile, readMIDIFile, writeMIDIFile
export BPM, bpm, qpm, time_signature, tempochanges, ms_per_tick

"""
    MIDIFile <: Any
Type representing a file of MIDI data.

## Fields
* `format::UInt16` : The format of the file. Can be 0, 1 or 2.
* `tpq::Int16` : The time division of the track, ticks-per-quarter-note.
* `tracks::Array{MIDITrack, 1}` : The array of contained tracks.
"""
mutable struct MIDIFile
    format::UInt16 # Can be 0, 1 or 2
    tpq::Int16 # The time division of the track. Ticks per quarter note
    tracks::Vector{MIDITrack}
end
# Pretty print
function Base.show(io::IO, midi::MIDIFile) where {N}
	tnames = tracknames(midi)
	s = "MIDIFile (format=$(Int(midi.format)), tpq=$(midi.tpq)) "
	if any(!isequal(NOTRACKNAME), tnames) # we have tracknames
		s *= "with tracks:\n"
		for t in tnames
			s *= " "*t*"\n"
		end
	else # some track doesn't have a name
		s *= "with $(length(midi.tracks)) tracks"
	end
	print(io, s)
end


MIDIFile() = MIDIFile(0,960,MIDITrack[])

"""
    qpm(midi)
Return the QPM (quarter notes per minute) where the given `MIDIFile` was exported at.
Returns 120 if not found.
"""
function qpm(t::MIDI.MIDIFile)
    # Find the one that corresponds to Set Tempo:
    # The event tttttt corresponds to the command
    # FF 51 03 tttttt Set Tempo (in microseconds per MIDI quarter-note)
    # See here (page 8):
    # http://www.cs.cmu.edu/~music/cmsip/readings/Standard-MIDI-file-format-updated.pdf
    for event in t.tracks[1].events
        if event isa SetTempo
            return 6e7 / event.tempo
        end
    end

    # Default QPM if it is not present in the MIDI file.
    @warn """The Set Tempo event is not present in the given MIDI file.
    A default value of 120.0 quarter notes per minute is returned."""
    return 120.0
end

"""
    bpm(midi)
Return the BPM where the given `MIDIFile` was exported at.
Returns QPM if not found.
"""
function bpm(t::MIDI.MIDIFile)
    cc = -1

    # Find the one that corresponds to Time Signature:
    # FF 58 04 nn dd cc bb Time Signature
    # See here (page 8):
    # http://www.cs.cmu.edu/~music/cmsip/readings/Standard-MIDI-file-format-updated.pdf
    for event in t.tracks[1].events
        if event isa TimeSignature
            cc = event.clockticks
            break
        end
    end

    if cc == -1
        @warn """The Time Signature event is not present in the given MIDI file.
        A default value of 24 cc (clocks per metronome click) is used for calculating the BPM."""
        # Default cc if not found
        cc = 24
    end

    bpm = qpm(t) * 24 / cc
end

# Deprecated
"""
    BPM(midi)
Return the BPM where the given `MIDIFile` was exported at.
Returns 120 if not found.
"""
function BPM(t::MIDI.MIDIFile)
    @warn """This function is deprecated.
    It returns quarter notes per minute instead of beats per minute.
    Please use `bpm` for beats per minute and `qpm` for quarter notes per minute."""

    # Find the one that corresponds to Set-Time:
    # The event tttttt corresponds to the command
    # FF 51 03 tttttt Set Tempo (in microseconds per MIDI quarter-note)
    # See here (page 8):
    # http://www.cs.cmu.edu/~music/cmsip/readings/Standard-MIDI-file-format-updated.pdf
    for event in t.tracks[1].events
        if event isa SetTempo
            return 6e7 / event.tempo
        end
    end

    # Default BPM if it is not present in the MIDI file.
    @warn """The Set Tempo event is not present in the given MIDI file.
    A default value of 120.0 quarter notes per minute is returned."""
    return 120.0
end

"""
    time_signature(midi)
Return the time signature of the given `MIDIFile`.
Returns 4/4 if it doesn't find a time signature.
"""
function time_signature(t::MIDI.MIDIFile)
    # Find the one that corresponds to Time Signature:
    # FF 58 04 nn dd cc bb Time Signature
    # See here (page 8):
    # http://www.cs.cmu.edu/~music/cmsip/readings/Standard-MIDI-file-format-updated.pdf
    for event in t.tracks[1].events
        if event isa TimeSignature
            ts = string(event.numerator) * "/" * string(event.denominator)
            return ts
        end
    end

    @warn """The Time Signature event is not present in the given MIDI file.
    A default value of 4/4 is returned."""

    # Default time signature if it is not present in the file
    return "4/4"
end

"""
    tempochanges(midi)
Return a vector of (position, tempo) tuples for all the tempo events in the given `MIDIFile`
where position is in absolute time (from the beginning of the file) in ticks
and tempo is in quarter notes per minute.
Returns [(0, 120.0)] if there are no tempo events.
"""
function tempochanges(midi::MIDIFile)
    # Stores (position, tempo) pairs
    # Calls qpm() to store the first tempo value
    # If there is no tempo event, qpm will warn and return 120.0
    tempo_changes = [(0, qpm(midi))]
    position = 0
    for event in midi.tracks[1].events
        position += event.dT
        if event isa SetTempo
            qpm = 6e7 / event.tempo

            # Allow only one tempo change at the beginning
            if position == 0
                tempo_changes = [(0, qpm)]
            else
                push!(tempo_changes, (position, qpm))
            end
        end
    end

    tempo_changes
end

"""
    ms_per_tick(tpq, qpm)
    ms_per_tick(midi::MIDIFile)
Return how many miliseconds is one tick, based
on the quarter notes per minute `qpm` and ticks per quarter note `tpq`.
"""
ms_per_tick(midi::MIDI.MIDIFile, qpm = qpm(midi)) = ms_per_tick(midi.tpq, qpm)
ms_per_tick(tpq, qpm) = (1000*60)/(qpm*tpq)

getnotes(midi::MIDIFile, trackno = midi.format == 0 ? 1 : 2) =
getnotes(midi.tracks[trackno], midi.tpq)
