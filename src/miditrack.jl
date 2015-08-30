#=
Track chunks begin with four bytes spelling out "MTrk", followed by the length
in bytes of the track (see readvariablelength in util.jl), followed by a sequence
of events.
=#
type MIDITrack
    events::Array{TrackEvent, 1}

    MIDITrack() = new(TrackEvent[])
end

function readtrack(f::IO)
    mtrk = join(map(char, read(f, Uint8, 4)))
    if mtrk != MTRK
        error("Not a valid midi file. Expected MTrk, got $(mtrk) starting at byte $(hex(position(f)-4, 2))")
    end
    track = MIDITrack()

    # Get the length in bytes of the track
    tracklength = ntoh(read(f, Uint32))

    trackstart = position(f)
    bytesread = 0
    laststatus = uint8(0) # Keeps track of running status
    while bytesread < tracklength
        # A track is made up of events. All events start with a variable length
        # value indicating the number of ticks (time) since the last event.

        # Get the time offset of the next event
        dT = readvariablelength(f)

        # Figure out the event type
        # Remember, endianness is byte order, not bit order. No need to ntoh here.
        event_start = read(f, Uint8)
        skip(f, -1)

        local event
        if ismidievent(event_start)
            event = readmidievent(dT, f, laststatus)
            laststatus = event.status
        elseif issysexevent(event_start)
            event = readsysexevent(dT, f)
            laststatus = uint8(0)
        elseif ismetaevent(event_start)
            event = readmetaevent(dT, f)
            laststatus = uint8(0)
        else
            error("Unrecognized event $(hex(event_start,2))")
        end
        push!(track.events, event)

        bytesread = position(f) - trackstart
    end

    # Validate that the track ends with a track end event
    lastevent = track.events[length(track.events)]
    if typeof(lastevent) != MetaEvent || lastevent.metatype != METATRACKEND
        error("Invalid track - does not end with track metaevent")
    else
        # strip the track end event - we don't need to worry about manipulating it
        track.events = track.events[1:length(track.events)-1]
    end

    track
end

function writetrack(f::IO, track::MIDITrack)
    write(f, convert(Array{Uint8, 1}, MTRK)) # Track identifier

    writingmidi = false
    previous_status = uint8(0)

    event_buffer = IOBuffer()

    for event in track.events
        if typeof(event) == MIDIEvent && previous_status != 0 && previous_status == event.status
            writeevent(event_buffer, event, previous_status)
        elseif typeof(event) == MIDIEvent
            writeevent(event_buffer, event)
            previous_status = event.status
        else
            writeevent(event_buffer, event)
            previous_status = uint8(uint8(0))
        end
    end

    bytes = takebuf_array(event_buffer)

    write(f, hton(uint32(length(bytes) + 4))) # 4 is the length of the trackend event.

    for b in bytes
        write(f, b)
    end

    # Write the track end event
    writeevent(f, MetaEvent(0, METATRACKEND, Uint8[]))
end

function addnote(track::MIDITrack, note::Note)
    for (status, position) in [(NOTEON, note.position), (NOTEOFF, note.position + note.duration)]
        trackposition = 0
        addedevent = false
        for (i, event) in enumerate(track.events)
            if previousdt + event.dT > position
                # Add to track at position
                newdt = note.position - trackposition
                status = status & note.channel

                insert!(track.events, i, MIDIEvent(newdt, status, uint8[note.value, note.velocity]))
                addedevent = true

                nextevent = track.events[i+1]
                nextevent.dT -= newdt

                break
            else
                trackposition += event.dT
            end
        end

        if !addedevent
            newdt = note.position - trackposition
            status = NOTEON & note.channel
            e = MIDIEvent(newdt, status, uint8[note.value, note.velocity])
            push!(track.events, e)
        end
    end
end
