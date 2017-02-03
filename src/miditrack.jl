export getnotes, addnote, addnotes

#=
Track chunks begin with four bytes spelling out "MTrk", followed by the length
in bytes of the track (see readvariablelength in util.jl), followed by a sequence
of events.
=#
type MIDITrack
    events::Array{TrackEvent, 1}

    MIDITrack() = new(TrackEvent[])
    MIDITrack(events) = new(events)
end

function readtrack(f::IO)
    mtrk = join(map(Char, read(f, UInt8, 4)))
    if mtrk != MTRK
        error("Not a valid MIDI file. Expected MTrk, got $(mtrk) starting at byte $(hex(position(f)-4, 2))")
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
    write(f, convert(Array{UInt8, 1}, MTRK)) # Track identifier

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

    bytes = takebuf_array(event_buffer)

    write(f, hton(UInt32(length(bytes))))
    write(f, bytes)
end

# Adds an event to a track, with an absolute time
function addevent(track::MIDITrack, time::Integer, newevent::TrackEvent)
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
    addnote(track::MIDITrack, note::Note)
Add given `note` to given `track`, internally doing all translations from
absolute time to relative time.
"""
function addnote(track::MIDITrack, note::Note)
    for (status, position) in [(NOTEON, note.position), (NOTEOFF, note.position + note.duration)]
        addevent(track, position, MIDIEvent(0, status | note.channel, UInt8[note.value, note.velocity]))
    end
end

"""
    addnotes(track::MIDITrack, notes::Vector{Note})
Add given `notes` to given `track`, internally doing all translations from
absolute time to relative time.
"""
function addnotes(track::MIDITrack, notes::Array{Note, 1})
    for note in notes
        addnote(track, note)
    end
end

"""
    getnotes(track::MIDITrack)
Find all NOTEON and NOTEOFF midi events in the `track` that correspond to
the same note (pitch) and convert them into
the `Note` datatype provided by this Package. Ordering is done based on position.

Returns: `Vector{Note}`.
"""
function getnotes(track::MIDITrack)
    notes = Note[]
    tracktime = UInt64(0)
    for (i, event) in enumerate(track.events)
        tracktime += event.dT
        # Read through events until a noteon with velocity higher tha 0 is found 
        if isa(event, MIDIEvent) && event.status & 0xF0 == NOTEON && event.data[2] > 0
            duration = UInt64(0)
            for event2 in track.events[i+1:length(track.events)]
                duration += event2.dT
                # If we have a MIDI event & it's a noteoff (or a note on with 0 velocity), and it's for the same note as the first event we found, make a note
                # Many MIDI files will encode note offs as note ons with velocity zero
                if isa(event2, MIDI.MIDIEvent) && (event2.status & 0xF0 == MIDI.NOTEOFF || (event2.status & 0xF0 == MIDI.NOTEON && event2.data[2] == 0)) && event.data[1] == event2.data[1]
                    push!(notes, Note(event.data[1], duration, tracktime, event.status & 0x0F, event.data[2]))
                    break
                end
            end
        end
    end
    sort!(notes, lt=((x, y)->x.position<y.position))
end

# Change the program (instrument) on the given channel. Time is absolute, not relative to the last event.
function programchange(track::MIDITrack, time::Integer, channel::UInt8, program::UInt8)
    program = program - 1 # Program changes are typically given in range 1-128, but represented internally as 0-127.
    addevent(track, time, MIDIEvent(0, PROGRAMCHANGE | channel, UInt8[program]))
end
