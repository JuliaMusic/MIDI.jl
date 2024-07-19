"""
    MIDITrack <: Any

`MIDITrack` is simply a container for `TrackEvents`, since its only field is
`events::Vector{TrackEvent}`.

Track chunks begin with four bytes spelling out "MTrk", followed by the length
(in bytes) of the track (see [`readvariablelength`](@ref)), followed by a sequence
of events.

The `empty!` function can be used to clear all events in the `MIDITrack`.
"""
mutable struct MIDITrack
    events::Vector{TrackEvent}
end
MIDITrack() = MIDITrack(TrackEvent[])
# Pretty print
function Base.show(io::IO, t::MIDITrack)
    L = length(t.events)
    M = count(x -> x isa MIDIEvent, t.events)
    T = count(x -> x isa MetaEvent, t.events)
    X = L - M - T
    print(io, "$(L)-event MIDITrack: $M MIDI, $T Meta, $X Sysex")
end

empty!(t::MIDITrack) = empty!(t.events)


function readtrack(f::IO)

    mtrk = join(map(Char, read!(f, Array{UInt8}(undef, 4))))
    if mtrk != MTRK
        error("Not a valid MIDI file. Expected MTrk, got $(mtrk) starting at byte $(string(position(f)-4, base = 16, pad = 2))")
    end
    track = MIDITrack()

    # Get the length in bytes of the track
    tracklength = ntoh(read(f, UInt32))

    trackstart = position(f)
    bytesread = 0
    laststatus = UInt8(0) # Keeps track of running status
    while bytesread < tracklength
        # A track is made up of events. All events start with a variable length
        # value indicating the number of ticks (time) since the last event.

        # Get the time offset of the next event
        dT = readvariablelength(f)

        # Figure out the event type
        # Remember, endianness is byte order, not bit order. No need to ntoh here.
        event_start = read(f, UInt8)
        skip(f, -1)

        local event
        if isMIDIevent(event_start)
            event = readMIDIevent(dT, f, laststatus)
            laststatus = event.status
        elseif issysexevent(event_start)
            event = readsysexevent(dT, f)
            laststatus = UInt8(0)
        elseif ismetaevent(event_start)
            event = readmetaevent(dT, f)
            laststatus = UInt8(0)
        else
            error("Unrecognized event $(hex(event_start,2))")
        end
        push!(track.events, event)

        bytesread = position(f) - trackstart
    end

    # Validate that the track ends with a track end event
    lastevent = track.events[length(track.events)]
    if !isa(lastevent, EndOfTrackEvent)
        error("Invalid track - does not end with track metaevent")
    else
        # strip the track end event - we don't need to worry about manipulating it
        track.events = track.events[1:length(track.events)-1]
    end

    track
end

function writetrack(f::IO, track::MIDITrack)
    write(f, MTRK) # Track identifier

    writingMIDI = false
    previous_status = UInt8(0)

    event_buffer = IOBuffer()

    for event in track.events
        if isa(event, MIDIEvent) && previous_status != 0 && previous_status == event.status
            writeevent(event_buffer, event, false)
        elseif isa(event, MIDIEvent)
            writeevent(event_buffer, event)
            previous_status = event.status
        else
            writeevent(event_buffer, event)
            previous_status = UInt8(0)
        end
    end

    # Write the track end event
    writeevent(event_buffer, EndOfTrackEvent(0))

    bytes = take!(event_buffer)

    write(f, hton(UInt32(length(bytes))))
    write(f, bytes)
end

"""
    addevent!(track::MIDITrack, time::Int, event::TrackEvent)
Add an event to the `track` at given `time`. The `time` is in absolute time,
not relative.

If you want to add multiple events in one go, you should use the [`addevents!`](@ref)
function instead.
"""
function addevent!(track::MIDITrack, time::Integer, newevent::TrackEvent)
    tracktime = 0
    addedevent = false
    for (i, event) in enumerate(track.events)
        if tracktime + event.dT > time
            # Add to track at position
            newdt = time - tracktime
            newevent.dT = newdt

            insert!(track.events, i, newevent)
            addedevent = true

            nextevent = track.events[i+1]
            nextevent.dT -= newdt

            break
        else
            tracktime += event.dT
        end
    end

    if !addedevent
        newdt = time - tracktime
        newevent.dT = newdt
        push!(track.events, newevent)
    end
end

"""
    addevent_hint!(track::MIDITrack, time::Int, event::TrackEvent,
                    eventindex::UInt, eventtime::UInt)

Add an event to the `track` at given `time`. The `time` is in absolute time,
not relative. `eventindex` and `eventtime` have to be the index and the absolute
time of a known event in `track` which lays BEFORE the position where `event` shall be added.
This shortens the search for the correct position for `event` by skipping all
`TrackEvents` before the specified one.

Returns the index and absolute time of the added event.
"""
function addevent_hint!(track::MIDITrack, time::Integer, newevent::TrackEvent,
                    eventindex::Integer, eventtime::Integer)
    # start at known position
    eventtime > time && throw(ArgumentError("Eventtime has to be smaller than time."))
    tracktime = eventtime
    startindex = eventindex+1

    addedevent = false

    # start at known index
    for i = (startindex):length(track.events)
        if tracktime + track.events[i].dT > time

            # Add to track at position
            newdt = time - tracktime
            newevent.dT = newdt
            insert!(track.events, i, newevent)
            addedevent = true
            eventindex = i

            # update dT of following event
            nextevent = track.events[i+1]
            nextevent.dT -= newdt

            break
        else
            tracktime += track.events[i].dT
        end
    end

    if !addedevent
        newdt = time - tracktime
        newevent.dT = newdt
        push!(track.events, newevent)
        eventindex = length(track.events)
    end
    return (eventindex, Int(time))
end

"""
    addevents!(track::MIDITrack, times, events)

Add given `events` to given `track` at given `times`, internally
doing all translations from absolute time to relative time.

Using this function is more efficient than a loop over single [`addevent!`](@ref)
calls.
"""
function addevents!(track::MIDITrack, times::AbstractArray{Int}, events)

    # get a permutation that gives temporal order
    if issorted(times)
        perm = 1:length(times)
    else
        perm = sortperm(times)
    end

    # add the notes to the track using the faster version of addevent
    eventindex = 0
    eventtime = 0
    for i = 1:length(times)
        eventindex, eventtime = addevent_hint!(
            track, times[perm[i]], events[perm[i]], eventindex, eventtime
        )
    end
end

"""
    addnotes!(track::MIDITrack, notes)
Add given `notes` to given `track`, internally doing all translations from
absolute time to relative time.
"""
function addnotes!(track::MIDITrack, notes)
    # generate all events to be written to the track
    events = Vector{MIDI.TrackEvent}()
    posis = Vector{Int}()
    for anote in notes
        note = Note(anote)
        for (event, position) in [(NoteOnEvent, note.position), (NoteOffEvent, note.position + note.duration)]
            push!(events, event(0, Int(note.pitch), Int(note.velocity), channel = note.channel))
            push!(posis, position)
        end
    end

    addevents!(track, posis, events)
end

"""
    addnote!(track::MIDITrack, note::AbstractNote)
Add given `note` to given `track`, internally doing the translation from
absolute time to relative time.
"""
function addnote!(track::MIDITrack, anote::AbstractNote)
    # Convert to `Note
    note = Note(anote)
    for (event, position) in [(NoteOnEvent, note.position), (NoteOffEvent, note.position + note.duration)]
        addevent!(track, position, event(0, Int(note.pitch), Int(note.velocity), channel = note.channel))
    end
end


"""
    getnotes(midi::MIDIFile [, trackno])

Find all `NoteOnEvent`s and `NoteOffEvent`s in the `trackno` track of a `midi`
(default 1 or 2),
that correspond to the same note value (pitch) and convert them into
the `Note` datatype. There are special cases where NoteOffEvent is actually
encoded as NoteOnEvent with 0 velocity, but `getnotes` takes care of this.

Notice that the first track of a `midi` typically doesn't have any notes,
which is why the function defaults to track 2.

    getnotes(track::MIDITrack, tpq = 960)
Find the notes from `track` directly, passing also the ticks per quarter note.

Returns: `Notes{Note}`, setting the ticks per quarter note as `tpq`. You can find
the originally exported
ticks per quarter note from the original `MIDIFile` through `midi.tpq`.
"""
function getnotes(track::MIDITrack, tpq = 960)
    notes = Note[]
    tracktime = UInt(0)
    for (i, event) in enumerate(track.events)
        tracktime += event.dT
        # Read through events until a noteon with velocity higher tha 0 is found
        if event isa NoteOnEvent && event.velocity > 0
            duration = UInt(0)
            for event2 in track.events[i+1:length(track.events)]
                duration += event2.dT
                # If we have a MIDI event & it's a noteoff (or a note on with 0 velocity), and it's for the same note as the first event we found, make a note
                # Many MIDI files will encode note offs as note ons with velocity zero
                if (event2 isa NoteOffEvent || (event2 isa NoteOnEvent && event2.velocity == 0)) && event.note == event2.note
                    push!(notes, Note(event.note, event.velocity, tracktime, duration, channelnumber(event)))
                    break
                end
            end
        end
    end
    sort!(notes, lt=((x, y)->x.position<y.position))
    return Notes(notes, tpq)
end

"""
    programchange(track::MIDITrack, time::Integer, channel::UInt8, program::UInt8)

Change the program (instrument) on the given channel.
Time is absolute, not relative to the last event.

The `program` must be specified in the range 1-128, **not** in 0-127!
"""
function programchange(track::MIDITrack, time::Int, channel::Int, program::Int)
    if !(1 <= program <= 128)
        throw(ArgumentError("The `program` must be specified in the range 1-128"))
    end
    program -= 1
    addevent!(track, time, ProgramChangeEvent(0, program, channel = channel))
end


"""
    get_abs_pos(track::MIDITrack, idxs)
Return the absolute positions (since track start) of the events given by the
indices `idxs` of `track.events`.
"""
function get_abs_pos(idxs, track::MIDITrack)
    abspos = Int[]
    evtime = 0
    j = 1; L = length(idxs)
    for (i, event) in enumerate(track.events)
        evtime += event.dT
        if i == idxs[j]
            push!(abspos, evtime)
            j += 1
            j == L + 1 && return abspos
        end
    end
    return abspos
end
