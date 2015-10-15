type SysexEvent <: TrackEvent
    dT::Int
    data::Array{UInt8,1}
end

function issysexevent(b::UInt8)
    b == 0xF0
end

function readsysexevent(dT::UInt8, f::IO)
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
    writevariablelength(f, event.dT)
    write(f, SYSEX)
    writevariablelength(f, length(event.data) + 1) # +1 for the ending F7
    write(f, event.data)
    write(f, 0xF7)
end

export SysexEvent
