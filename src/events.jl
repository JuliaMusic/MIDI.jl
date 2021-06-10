export encode

# Define the spec which maps from type byte to the type definitions
const spec = Dict(
    0x00 => (
        type = :SequenceNumber,
        fields = [(:number, Int)],
        decode = :(ntoh.(reinterpret(UInt16, data))),
        encode = :(UInt8.([event.number >> 8 & 0xFF, event.number & 0xFF]))
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
        decode = :(Int.(data)),
        encode = :(UInt8(event.channel))
    ),
    0x2F => (
        type = :EndOfTrack,
        fields = [],
        decode = :([]),
        encode = :(UInt8[])
    ),
    0x51 => (
        type = :SetTempo, 
        fields = [(:tempo, Int)],
        decode = :(ntoh.(reinterpret(UInt32, pushfirst!(data, 0x00)))),
        encode = :(UInt8.([event.tempo >> 16, event.tempo >> 8 & 0xFF, event.tempo & 0xFF]))
    ),
    # TODO: Add SMPTEOffset
    0x58 => (
        type = :TimeSignature, 
        fields = [(:numerator, Int), (:denominator, Int), (:clockticks, Int), (:notated32nd_notes, Int)],
        decode = :(Int.([data[1], 2^data[2], data[3:4]...])),
        encode = :(UInt8.([event.numerator, log2(event.denominator), event.clockticks, event.notated32nd_notes]))
    ),
    0x59 => (
        type = :KeySignature, 
        fields = [(:sf, Int), (:mi, Int)],
        decode = :(Int.(data[1:2])),
        encode = :(UInt8.([event.sf, event.mi]))
    ),
)

# Store the defs for text-only events separately to avoid repetition
text_defs = (
    fields = [(:text, String)],
    decode = :([join(Char.(data))]),
    encode = :(UInt8.(collect(event.text)))
)

# Create a map from EventType to type byte
const type2byte = Dict((value isa Symbol ? value : value.type) => key for (key, value) in spec)

# Define a struct, constructor and encode function for a given type
function define_type(type, fields, decode, encode_)
    @eval begin
        mutable struct $(type) <: MetaEvent
            dT::Int
            $(fields...)
        end

        function $type(dT::Int, data::Vector{UInt8})
            $type(dT, $decode...)
        end
        
        function encode(event::$type)
            $encode_
        end

        export $type
    end
end

# Call define_type for all events in the spec and create the types
for defs in values(spec)
    if defs isa Symbol
        # It is a text-only event
        # fields and encode/decode expressions for text-only events are stored separately
        type = defs
        fields, decode, encode = text_defs
    else
        type, fields, decode, encode = defs
    end
    fields = [:($(fieldname)::$(fieldtype)) for (fieldname, fieldtype) in fields]
    define_type(type, fields, decode, encode)
end