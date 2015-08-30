type SysexEvent <: TrackEvent
    dT::Int
    status::Uint8
    data::Array{Uint8,1}
end

function issysexevent(b::Uint8)
    b == 0xF0
end

function readsysexevent(dT::Uint8, f::IOStream)
    data = Uint8[]
    statusbyte = read(f, Uint8)
    b = read(f, Uint8)
    while isdatabyte(b)
        push!(data, b)
        if eof(f)
            return SysexEvent(dT, statusbyte, data)
        end
        b = read(f, Uint8)
    end
    skip(f, -1)

    SysexEvent(dT, statusbyte, data)
end

function writeevent(f::IOStream, event::SysexEvent)
    write(f, SYSEX)
    writevariablelength(f, event.dT)
    write(f, event.status)
    for b in event.data
        write(f, b)
    end
end
