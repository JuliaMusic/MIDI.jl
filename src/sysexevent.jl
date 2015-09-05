type SysexEvent <: TrackEvent
    dT::Int
    data::Array{Uint8,1}
end

function issysexevent(b::Uint8)
    b == 0xF0
end

function readsysexevent(dT::Uint8, f::IO)
    data = Uint8[]
    # Read the length, but don't bother recording it since we can calculate it from the rest of the stream.
    readvariablelength(f)
    b = read(f, Uint8)
    while isdatabyte(b)
        push!(data, b)
        if eof(f)
            return SysexEvent(dT, statusbyte, data)
        end
        b = read(f, Uint8)
    end
    # The last byte of sysex event is F7. We leave that out of the data, and write it back when we write the event.

    SysexEvent(dT, data)
end

function writeevent(f::IO, event::SysexEvent)
    writevariablelength(f, event.dT)
    write(f, SYSEX)
    writevariablelength(f, length(event.data) + 1) # +1 for the ending F7
    for b in event.data
        write(f, b)
    end
    write(f, 0xF7)
end

export SysexEvent
