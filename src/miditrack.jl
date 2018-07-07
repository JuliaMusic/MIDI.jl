export getnotes, addnote!, addnotes!, addevent!, addevents!, trackname, addtrackname!
export MIDITrack

"""
    MIDITrack <: Any

`MIDITrack` is simply a container for `TrackEvents`, since its only field is
`events::Vector{TrackEvent}`.

Track chunks begin with four bytes spelling out "MTrk", followed by the length
(in bytes) of the track (see `readvariablelength`), followed by a sequence
of events.
"""
mutable struct MIDITrack
    events::Vector{TrackEvent}
end
MIDITrack() = MIDITrack(TrackEvent[])

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
    if !isa(lastevent, MetaEvent) || lastevent.metatype != METATRACKEND
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
    writeevent(event_buffer, MetaEvent(0, METATRACKEND, UInt8[]))

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
        perm = collect(1:length(times))
    else
        perm = sortperm(times)
    end

    # add the notes to the track using the faster version of addevent
    eventindex = 0
    eventtime = 0
    for i = 1:length(times)
        eventindex, eventtime = addevent_hint!(track,times[perm[i]], events[perm[i]], eventindex, eventtime)
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
        for (status, position) in [(NOTEON, note.position), (NOTEOFF, note.position + note.duration)]
            push!(events, MIDIEvent(0, status | note.channel, UInt8[note.pitch, note.velocity]))
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
    # Convert to `Note`
    note = Note(anote)
    for (status, position) in [(NOTEON, note.position), (NOTEOFF, note.position + note.duration)]
        addevent!(track, position, MIDIEvent(0, status | note.channel, UInt8[note.pitch, note.velocity]))
    end
end


"""
    getnotes(midi::MIDIFile, trackno = 2)

Find all NOTEON and NOTEOFF midi events in the `trackno` track of a `midi`,
that correspond to the same note value (pitch) and convert them into
the `Note` datatype. There are special cases where NOTEOFF is actually encoded as NOTEON with 0 velocity.
`getnotes` takes care of this.

Notice that the first track of a `midi` doesn't have any notes.

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
        if isa(event, MIDIEvent) && event.status & 0xF0 == NOTEON && event.data[2] > 0
            duration = UInt(0)
            for event2 in track.events[i+1:length(track.events)]
                duration += event2.dT
                # If we have a MIDI event & it's a noteoff (or a note on with 0 velocity), and it's for the same note as the first event we found, make a note
                # Many MIDI files will encode note offs as note ons with velocity zero
                if isa(event2, MIDI.MIDIEvent) && (event2.status & 0xF0 == MIDI.NOTEOFF || (event2.status & 0xF0 == MIDI.NOTEON && event2.data[2] == 0)) && event.data[1] == event2.data[1]
                    push!(notes, Note(event.data[1], event.data[2], tracktime, duration, event.status & 0x0F))
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
function programchange(track::MIDITrack, time::Integer, channel::UInt8, program::UInt8)
    @warn "This function has not been tested. Please test it before using "*
    "and be kind enough to report whether it worked!"
    program -= 1
    addevent!(track, time, MIDIEvent(0, PROGRAMCHANGE | channel, UInt8[program]))
end

"""
    trackname(track::MIDI.MIDITrack)

Return the name of the given [`MIDITrack`](@ref) as a string,
by finding the "track name" [`MetaEvent`](@ref).
"""
function trackname(track::MIDI.MIDITrack)

    pos = findnameevent(track)
    if pos == 0
        return "No track name found"
    # check if there really is a name
    elseif length(track.events[pos].data) == 0
        return "No track name found"
    else
        event = track.events[pos]
        # extract the name (string(Char()) takes care of ASCII encoding)
        trackname = string(Char(event.data[1]))
        for c in event.data[2:end]
            trackname *= string(Char(c))
        end
        return trackname
    end
end

"""
    addtrackname!(track::MIDI.MIDITrack, name::String)

Add a name of the given [`MIDITrack`](@ref) by attaching the correct
"track name" [`MetaEvent`](@ref) to the track.
"""
function addtrackname!(track::MIDI.MIDITrack, name::String)
    # construct fitting name event
    data = UInt8[]
    for i = 1:length(name)
        push!(data, UInt8(name[i]))
    end
    meta = MetaEvent(0,0x03,data)

    # remove existing name
    prev = findnameevent(track)
    if prev != 0
        deleteat!(track.events, prev)
    end

    # add event to track
    addevent!(track, 0, meta)
end

function findnameevent(track::MIDI.MIDITrack)
    # find track name MetaEvent
    position = 0
    for (i,event) in enumerate(track.events)
        if isa(event, MIDI.MetaEvent) && event.metatype == 0x03
            position = i
            break
        end
    end
    return position
end
