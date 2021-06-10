const spec = Dict(
    0x00 => (
        type = :SequenceNumber,
        fields = [(:number, Int)],
        decode = :(ntoh.(reinterpret(UInt16, data)))
    ),
    0x01 => :TextEvent,
    0x02 => :CopyrightNotice,
    0x03 => :TrackName,
    0x04 => :InstrumentName,
    0x05 => :Lyric,
    0x06 => :Marker,
    0x07 => :CuePoint,
    0x20 => (
        type = :MIDIChannelPrefix,
        fields = [(:channel, Int)],
        decode =  :(Int.(data))
    ),
    0x2F => (
        type = :EndOfTrack,
        fields = [],
        decode = :([])
    ),
    0x51 => (
        type = :SetTempo, 
        fields = [(:tempo, Int)],
        decode = :(ntoh.(reinterpret(UInt32, pushfirst!(data, 0x00))))
    ),
    # TODO: Add SMPTEOffset
    0x58 => (
        type = :TimeSignature, 
        fields = [(:numerator, Int), (:denominator, Int)],
        decode = :(Int.([data[1], 2^data[2]]))
    ),
    0x59 => (
        type = :KeySignature, 
        fields = [(:sf, Int), (:mi, Int)],
        decode = :(Int.(data[1:2]))
    ),
)

text_defs = (
    fields = [(:text, String)],
    decode = :([join(Char.(data))])
)

const type2byte = Dict((value isa Symbol ? value : value.type) => key for (key, value) in spec)

function define_type(type, fields, decode)
    @eval begin
        mutable struct $(type) <: MetaEvent
            dT::Int
            $(fields...)
        end

        function $type(dT::Int, data::Vector{UInt8})
            $type(dT, $decode...)
        end
        
        export $type
    end
end

for defs in values(spec)
    if defs isa Symbol
        # It is a text-only event
        type = defs
        fields, decode = text_defs
    else
        type, fields, decode = defs
    end
    fields = [:($(fieldname)::$(fieldtype)) for (fieldname, fieldtype) in fields]
    define_type(type, fields, decode)
end

#=
function Base.show(io::IO, event::T) where {T <: MetaEvent}
    print(io, T, " ")
    for field in fieldnames(T)
        print(io, "$field = $(getfield(event, field)) | ")
    end
end
=#

#=
function TrackName(dT::Int, data::Vector{UInt8})
    name = join(Char.(data))
    TrackName(dT, name)
end

function SetTempo(dT::Int, data::Vector{UInt8})
    pushfirst!(data, 0x00)
    tempo = ntoh(reinterpret(UInt32, data)[1])
    SetTempo(dT, tempo)
end

function TimeSignature(dT::Int, data::Vector{UInt8})
    nn, dd = Int.(data[1:2])
    TimeSignature(dT, nn, 2^dd)
end

function KeySignature(dT::Int, data::Vector{UInt8})
    sf, mi = Int.(data[1:2])
    KeySignature(dT, sf, mi)
end

function EndOfTrack(dT::Int, data::Vector{UInt8})
    !isempty(data) && error("Unwanted data at the end of track")
    EndOfTrack(dT)
end

function ChannelPrefix(dT::Int, data::Vector{UInt8})
    cc = Int(data[1])
    ChannelPrefix(dT, cc)
end
=#