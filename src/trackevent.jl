export TrackEvent, MetaEvent, MIDIEvent, SysexEvent

"""
    TrackEvent <: Any
Abstract supertype for all MIDI events.

All track events begin with a variable length time value
(see [`readvariablelength`](@ref)) and have a field named `dT` which contains it.
This number notes after how many ticks since the last event does the current
even takes place.

`MIDIEvent`s then resume with a MIDI channel message
defined in `constants.jl`. They're followed by 1 or 2 bytes, depending on the
channel message (see `MIDI.EVENTTYPETOLENGTH`).
If no valid channel message is identified,
the previous seen channel message is used. After that the MIDI command is encoded.

`MetaEvent`s and `SysexEvent`s both resume with a specific byte (see `constants.jl`).
"""
abstract type TrackEvent end

#####################################################################################
# MetaEvent
#####################################################################################
"""
    MetaEvent <: TrackEvent
See [`TrackEvent`](@ref).
"""
abstract type MetaEvent <: TrackEvent end

@inline ismetaevent(b::UInt8) = b == 0xFF

function readmetaevent(dT::Int, f::IO)
    # Meta events are 0xFF - type (1 byte) - variable length data length - data bytes
    skip(f, 1) # Skip the 0xff that starts the event
    metatype = read(f, UInt8)
    type = MIDI_EVENTS_SPEC[metatype]
    datalength = readvariablelength(f)
    data = read!(f, Array{UInt8}(undef, datalength))
    type(dT, metatype, data)
end

function writeevent(f::IO, event::MetaEvent)
    if event.dT < 0
        error("Negative deltas are not allowed. Please reorder your events.")
    end
    writevariablelength(f, event.dT)
    write(f, META)
    # Write metatype byte
    write(f, event.metatype)
    data = encode(event)
    writevariablelength(f, convert(Int, length(data)))
    write(f, data)
end


#####################################################################################
# MidiEvent
#####################################################################################
"""
    MIDIEvent <: TrackEvent
See [`TrackEvent`](@ref).
"""
abstract type MIDIEvent <: TrackEvent end

function isstatusbyte(b::UInt8)
    (b & 0b10000000) == 0b10000000
end

function isdatabyte(b::UInt8)
    !isstatusbyte(b)
end

function isMIDIevent(b::UInt8)
    !ismetaevent(b) && !issysexevent(b)
end

function channelnumber(m::MIDIEvent)
    0x0F & m.status
end

function readMIDIevent(dT::Int, f::IO, laststatus::UInt8)
    statusbyte = read(f, UInt8)
    highnybble = statusbyte & 0b11110000

    toread = 0
    if haskey(EVENTTYPETOLENGTH, highnybble)
        laststatus = statusbyte
        toread = EVENTTYPETOLENGTH[highnybble]
    else # Running status is in use
        toread = EVENTTYPETOLENGTH[laststatus & 0b11110000]
        statusbyte = laststatus
        skip(f, -1)
    end

    data = read!(f, Array{UInt8}(undef, toread))

    type = MIDI_EVENTS_SPEC[statusbyte & 0xF0]
    type(dT, statusbyte, data)
end

function writeevent(f::IO, event::MIDIEvent, writestatus::Bool)
    event.dT < 0 && error(
    "Negative deltas are not allowed. Please reorder your events.")

    writevariablelength(f, event.dT)

    if writestatus
        write(f, event.status)
    end

    write(f, encode(event))
end

function writeevent(f::IO, event::MIDIEvent)
    writeevent(f, event, true)
end



#####################################################################################
# SysexEvent
#####################################################################################
"""
    SysexEvent <: TrackEvent
See [`TrackEvent`](@ref).
"""
mutable struct SysexEvent <: TrackEvent
    dT::Int
    data::Array{UInt8,1}
end

issysexevent(b::UInt8) = b == 0xF0

function readsysexevent(dT::Int, f::IO)
    data = UInt8[]
    read(f, UInt8) # Eat the SYSEX that's on top of f
    datalength = readvariablelength(f)
    b = read(f, UInt8)
    while isdatabyte(b)
        push!(data, b)
        b = read(f, UInt8)
    end

    if b != 0xF7
        error("Invalid sysex event, did not end with 0xF7")
    end
    # The last byte of sysex event is F7. We leave that out of the data, and write it back when we write the event.

    if length(data) + 1 != datalength
        error("Invalid sysex event. Expected $(datalength) bytes, received $(length(data) + 1)")
    end
    SysexEvent(dT, data)
end

function writeevent(f::IO, event::SysexEvent)
    if event.dT < 0
        error("Negative deltas are not allowed. Please reorder your events.")
    end

    writevariablelength(f, event.dT)
    write(f, SYSEX)
    writevariablelength(f, length(event.data) + 1) # +1 for the ending F7
    write(f, event.data)
    write(f, 0xF7)
end
