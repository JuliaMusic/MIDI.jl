type MIDIEvent <: TrackEvent
    dT::Int
    status::Uint8
    data::Array{Uint8,1}
end

function isstatusbyte(b::Uint8)
    (b & 0b10000000) == 0b10000000
end

function isdatabyte(b::Uint8)
    !isstatusbyte(b)
end

function ismidievent(b::Uint8)
    !ismetaevent(b) && !issysexevent(b)
end

function channelnumber(m::MIDIEvent)
    0x0F & m.status
end

laststatus = 0
function readmidievent(dT::Int64, f::IOStream)
    data = Uint8[]

    statusbyte = read(f, Uint8)
    highnybble = statusbyte & 0b11110000
    global laststatus

    toread = 0
    if haskey(EVENTTYPETOLENGTH, highnybble)
        laststatus = statusbyte
        toread = EVENTTYPETOLENGTH[highnybble]
    else # Running status is in use
        toread = EVENTTYPETOLENGTH[laststatus & 0b11110000]
        statusbyte = laststatus
        skip(f, -1)
    end

    bytecount = 0

    while bytecount < toread
        b = read(f, Uint8)
        push!(data, b)

        bytecount += 1
    end

    MIDIEvent(dT, statusbyte, data)
end

function writeevent(f::IOStream, event::MIDIEvent, status::Uint8)
    writevariablelength(f, event.dT)

    if status == 0
        write(f, event.status)
    end

    for b in event.data
        write(f, b)
    end
end

function writeevent(f::IOStream, event::MIDIEvent)
    writeevent(f, event, uint8(0))
end
