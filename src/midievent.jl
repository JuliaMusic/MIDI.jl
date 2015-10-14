type MIDIEvent <: TrackEvent
    dT::Int
    status::UInt8
    data::Array{UInt8,1}
end

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

function readMIDIevent(dT::Int64, f::IO, laststatus::UInt8)
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

    data = read(f, UInt8, toread)

    MIDIEvent(dT, statusbyte, data)
end

function writeevent(f::IO, event::MIDIEvent, writestatus::Bool)
    writevariablelength(f, event.dT)

    if writestatus
        write(f, event.status)
    end

    write(f, event.data)
end

function writeevent(f::IO, event::MIDIEvent)
    writeevent(f, event, true)
end
