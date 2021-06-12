export encode, decode

# Create a map from typebyte to the type definitions
const MIDI_EVENTS_DEFS = Dict(
    # MetaEvents
    0x00 => (
        type = :SequenceNumber,
        fields = ["number::Int"],
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
        fields = ["channel::Int"],
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
        fields = ["tempo::Int"],
        decode = :(ntoh.(reinterpret(UInt32, pushfirst!(data, 0x00)))),
        encode = :(UInt8.([event.tempo >> 16, event.tempo >> 8 & 0xFF, event.tempo & 0xFF]))
    ),
    # TODO: Add SMPTEOffset
    0x58 => (
        type = :TimeSignature,
        fields = ["numerator::Int", "denominator::Int", "clockticks::Int", "notated32nd_notes::Int"],
        decode = :(Int.([data[1], 2^data[2], data[3:4]...])),
        encode = :(UInt8.([event.numerator, log2(event.denominator), event.clockticks, event.notated32nd_notes]))
    ),
    0x59 => (
        type = :KeySignature,
        fields = ["semitones::Int", "scale::Int"],
        decode = :(Int.(data)),
        encode = :(UInt8.([event.semitones, event.scale]))
    ),

    # MidiEvents
    0x80 => (
        type = :NoteOff,
        fields = ["note::Int", "velocity::Int"],
        decode = :(Int.(data)),
        encode = :(UInt8.([event.note, event.velocity]))
    ),
    0x90 => (
        type = :NoteOn,
        fields = ["note::Int", "velocity::Int"],
        decode = :(Int.(data)),
        encode = :(UInt8.([event.note, event.velocity]))
    ),
    0xA0 => (
        type = :Aftertouch,
        fields = ["note::Int", "pressure::Int"],
        decode = :(Int.(data)),
        encode = :(UInt8.([event.note, event.pressure]))
    ),
    0xB0 => (
        type = :ControlChange,
        fields = ["controller::Int", "value::Int"],
        decode = :(Int.(data)),
        encode = :(UInt8.([event.controller, event.value]))
    ),
    0xC0 => (
        type = :ProgramChange,
        fields = ["program::Int"],
        decode = :(Int.(data)),
        encode = :(UInt8.([event.program]))
    ),
    0xD0 => (
        type = :ChannelPressure,
        fields = ["pressure::Int"],
        decode = :(Int.(data)),
        encode = :(UInt8.([event.pressure]))
    ),
    0xE0 => (
        type = :PitchBend,
        fields = ["pitch::Int"],
        decode = :(Int.((ntoh(reinterpret(UInt16, [0x00, data[2]])[1]) << 8 | data[1] << 1) >> 1)),
        encode = :(UInt8.([event.pitch & 0b01111111, event.pitch >> 7]))
    ),
)

# Store the defs for text-only events separately to avoid repetition
text_defs = (
    fields = ["metatype::UInt8", "text::String"],
    decode = :([join(Char.(data))]),
    encode = :(UInt8.(collect(event.text)))
)

# Create a map from EventType to type byte
const TYPE2BYTE = Dict((value isa Symbol ? value : value.type) => key for (key, value) in MIDI_EVENTS_DEFS)

# Define a struct, constructor and encode function for a given type
function define_type(type, fields, decode, encode_, supertype)
    @eval begin
        mutable struct $type <: $supertype
            dT::Int
            $(fields...)
        end

        """    $($type)(dT::Int, data::Vector{UInt8})
        Returns a `$($type)` event from it's byte representation.
        """
        function $type(dT::Int, typebyte::UInt8, data::Vector{UInt8})
            $type(dT, typebyte, $decode...)
        end
        
        """    encode(event::$($type))
        Returns the byte representation of a `$($(type))` event.
        """
        function encode(event::$type)
            $encode_
        end

        export $type
    end
end

# Call define_type for all events in the MIDI_EVENTS_SPEC and create the types
for defs in values(MIDI_EVENTS_DEFS)
    if defs isa Symbol
        # It is a text-only event
        # fields and encode/decode expressions for text-only events are stored separately
        type = defs
        fields, decode, encode = text_defs
    else
        type, fields, decode, encode = defs
    end

    typebyte = TYPE2BYTE[type]
    if 0x80 <= typebyte <= 0xEF
        supertype = MIDIEvent
        # Adding common fields for all MIDI events
        prepend!(fields, ["status::UInt8", "channel::Int"])
    else
        supertype = MetaEvent
        if !(0x01 <= typebyte <= 0x07)
            # text-only events already have the metatype field
            pushfirst!(fields, "metatype::UInt8")
        end
    end

    # Parse the fields into a Fieldname::Type expression
    fields = Meta.parse.(fields)
    define_type(type, fields, decode, encode, supertype)
end

# Create a map from typebyte to type
const MIDI_EVENTS_SPEC = Dict(key => eval(value isa Symbol ? value : value.type) for (key, value) in MIDI_EVENTS_DEFS)

"""    SequenceNumber <: MetaEvent
The `SequenceNumber` event contains the number of a sequence
in type 0 and 1 MIDI files, or the pattern number in type 2 MIDI files.

## Fields:
* `dT::Int` : Delta time in ticks.
* `number::Int` : Sequence number.
"""
SequenceNumber

"""    TextEvent <: MetaEvent
The `TextEvent` contains a text within the MIDI file.

## Fields:
* `dT::Int` : Delta time in ticks.
* `text::String` : The text in the event.
"""
TextEvent

"""    CopyrightNotice <: MetaEvent
The `CopyrightNotice` event contains a copyright notice
in a MIDI file.

## Fields:
* `dT::Int` : Delta time in ticks.
* `text::String` : The copyright notice in text.
"""
CopyrightNotice

"""    TrackName <: MetaEvent
The `TrackName` event contains either the name of a MIDI sequence
(when in MIDI type 0 or MIDI type 2 files, or when in the first track of a MIDI type 1 file),
or the name of a MIDI track (when in other tracks of a MIDI type 1 file).

## Fields:
* `dT::Int` : Delta time in ticks.
* `text::String` : The track name in text.
"""
TrackName

"""    InstrumentName <: MetaEvent
The `InstrumentName` event contains the name of the instrument to be used in a track.

## Fields:
* `dT::Int` : Delta time in ticks.
* `text::String` : The instrument name in text.
"""
InstrumentName

"""    Lyric <: MetaEvent
The `Lyric` event contains the lyrics (usually syllables) in a MIDI file.

## Fields:
* `dT::Int` : Delta time in ticks.
* `text::String` : The lyric in text.
"""
Lyric

"""    Marker <: MetaEvent
The `Marker` event contains the text of a marker.

## Fields:
* `dT::Int` : Delta time in ticks.
* `text::String` : The marker text.
"""
Marker

"""    CuePoint <: MetaEvent
The `CuePoint` event contains a cue in a MIDI file.

## Fields:
* `dT::Int` : Delta time in ticks.
* `text::String` : The cue in text.
"""
CuePoint

"""    MIDIChannelPrefix <: MetaEvent
The `MIDIChannelPrefix` event contains a channel number to which
the following meta messages are sent to.

## Fields:
* `dT::Int` : Delta time in ticks.
* `channel::Int` : The channel number.
"""
MIDIChannelPrefix

"""    EndOfTrack <: MetaEvent
The `EndOfTrack` event denotes the end of a track.

## Fields:
* `dT::Int` : Delta time in ticks.
"""
EndOfTrack

"""    SetTempo <: MetaEvent
The `SetTempo` event sets the tempo of a MIDI sequence in terms of
microseconds per quarter note.

## Fields:
* `dT::Int` : Delta time in ticks.
* `tempo::Int` : The tempo in microseconds per quarter note.
"""
SetTempo

"""    TimeSignature <: MetaEvent
The `TimeSignature` event contains the time signature of a MIDI sequence.

## Fields:
* `dT::Int` : Delta time in ticks.
* `numerator::Int` : Numerator of the time signature.
* `denominator::Int` : Denominator of the time signature.
* `clockticks::Int` : MIDI clock ticks per click.
* `notated32nd_notes::Int` : Number of 32nd notes per beat.
"""
TimeSignature

"""    KeySignature <: MetaEvent
The `KeySignature` event contains the key signature and scale of a MIDI file.

## Fields:
* `dT::Int` : Delta time in ticks.
* `semitones::Int` : Number of flats or sharps.
* `scale::Int` : Scale of the MIDI file - 0 if the scale is major
   and 1 if the scale is minor.
"""
KeySignature

"""    NoteOff <: MIDIEvent
The `NoteOff` event informs a MIDI device to release a note.

## Fields:
* `dT::Int` : Delta time in ticks.
* `channel::Int` : The channel targeted by the event.
* `note::Int` : Note to turn off.
* `velocity::Int` : Velocity of the note.
"""
NoteOff

"""    NoteOn <: MIDIEvent
The `NoteOn` event informs a MIDI device to play a note.
A `NoteOn` event with 0 velocity acts as a `NoteOff` event.

## Fields:
* `dT::Int` : Delta time in ticks.
* `channel::Int` : The channel targeted by the event.
* `note::Int` : Note to turn on.
* `velocity::Int` : Velocity of the note.
"""
NoteOn

"""    Aftertouch <: MIDIEvent
The `Aftertouch` event informs a MIDI device to apply pressure to a note.

## Fields:
* `dT::Int` : Delta time in ticks.
* `channel::Int` : The channel targeted by the event.
* `note::Int` : Note to apply the pressure to.
* `pressure::Int` : Amount of pressure to be applied.
"""
Aftertouch

"""    ControlChange <: MIDIEvent
The `ControlChange` event informs a MIDI device to change the value of a controller.

## Fields:
* `dT::Int` : Delta time in ticks.
* `channel::Int` : The channel targeted by the event.
* `controller::Int` : Controller number.
* `value::Int` : Value received by the controller.
"""
ControlChange

"""    ProgramChange <: MIDIEvent
The `ProgramChange` event informs a MIDI device to select a program number
in a specific channel.

## Fields:
* `dT::Int` : Delta time in ticks.
* `channel::Int` : The channel targeted by the event.
* `program::Int` : The new program number.
"""
ProgramChange

"""    ChannelPressure <: MIDIEvent
The `ChannelPressure` event informs a MIDI device to apply pressure to a specific channel.

## Fields:
* `dT::Int` : Delta time in ticks.
* `channel::Int` : The channel targeted by the event.
* `pressure::Int` : Amount of the pressure to be applied.
"""
ChannelPressure

"""    PitchBend <: MIDIEvent
The `PitchBend` event informs a MIDI device to modify the pitch in a specific channel.

## Fields:
* `dT::Int` : Delta time in ticks.
* `channel::Int` : The channel targeted by the event.
* `pitch::Int` : Value of the pitch bend.
"""
PitchBend