type MetaEvent <: TrackEvent
    dT::Int
    metatype::Uint8
    data::Array{Uint8,1}
end

function ismetaevent(b::Uint8)
    b == 0xFF
end

function readmetaevent(dT::Int64, f::IOStream)
    # Meta events are 0xFF - type (1 byte) - variable length data length - data bytes
    skip(f, 1) # Skip the 0xff that starts the event
    data = Uint8[]
    metatype = read(f, Uint8)
    datalength = readvariablelength(f)
    bytecount = 0
    while bytecount < datalength
        b = read(f, Uint8)
        push!(data, b)
        bytecount += 1
    end

    MetaEvent(dT, metatype, data)
end

function writeevent(f::IOStream, event::MetaEvent)
    writevariablelength(f, event.dT)
    write(f, META)
    write(f, event.metatype)
    writevariablelength(f, convert(Int64, length(event.data)))
    for b in event.data
        write(f, b)
    end
end

export MetaEvent
