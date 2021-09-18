# Create a map from typebyte to the type definitions (not the actual types)
const MIDI_EVENTS_DEFS = Dict(
    # MetaEvents
    0x00 => (
        type = :SequenceNumberEvent,
        fields = ["number::Int"],
        decode = :(ntoh.(reinterpret(UInt16, data))),
        encode = :(UInt8.([event.number >> 8 & 0xFF, event.number & 0xFF]))
    ),

    # The definitions for text-only events are stored separately below to avoid repetition
    0x01 => :TextEvent,
    0x02 => :CopyrightNoticeEvent,
    0x03 => :TrackNameEvent,
    0x04 => :InstrumentNameEvent,
    0x05 => :LyricEvent,
    0x06 => :MarkerEvent,
    0x07 => :CuePointEvent,
    0x20 => (
        type = :MIDIChannelPrefixEvent,
        fields = ["channel::Int"],
        decode = :(Int.(data)),
        encode = :(UInt8(event.channel))
    ),
    0x21 => (
        type = :MIDIPort,
        fields = ["channel::Int"],
        decode = :(Int.(data)),
        encode = :(UInt8(event.channel))
    ),
    0x2F => (
        type = :EndOfTrackEvent,
        fields = [],
        decode = :([]),
        encode = :(UInt8[])
    ),
    0x51 => (
        type = :SetTempoEvent,
        fields = ["tempo::Int"],
        decode = :(Int.(ntoh.(reinterpret(UInt32, pushfirst!(data, 0x00))))),
        encode = :(UInt8.([event.tempo >> 16, event.tempo >> 8 & 0xFF, event.tempo & 0xFF]))
    ),
    # TODO: Add SMPTEOffset
    0x58 => (
        type = :TimeSignatureEvent,
        fields = ["numerator::Int", "denominator::Int", "clockticks::Int", "notated32nd_notes::Int"],
        decode = :(Int.([data[1], 2^data[2], data[3:4]...])),
        encode = :(UInt8.([event.numerator, log2(event.denominator), event.clockticks, event.notated32nd_notes]))
    ),
    0x59 => (
        type = :KeySignatureEvent,
        fields = ["semitones::Int", "scale::Int"],
        decode = :(Int.(data)),
        encode = :(UInt8.([event.semitones, event.scale]))
    ),

    # MidiEvents
    0x80 => (
        type = :NoteOffEvent,
        fields = ["note::Int", "velocity::Int"],
        decode = :(Int.(data)),
        encode = :(UInt8.([event.note, event.velocity]))
    ),
    0x90 => (
        type = :NoteOnEvent,
        fields = ["note::Int", "velocity::Int"],
        decode = :(Int.(data)),
        encode = :(UInt8.([event.note, event.velocity]))
    ),
    0xA0 => (
        type = :AftertouchEvent,
        fields = ["note::Int", "pressure::Int"],
        decode = :(Int.(data)),
        encode = :(UInt8.([event.note, event.pressure]))
    ),
    0xB0 => (
        type = :ControlChangeEvent,
        fields = ["controller::Int", "value::Int"],
        decode = :(Int.(data)),
        encode = :(UInt8.([event.controller, event.value]))
    ),
    0xC0 => (
        type = :ProgramChangeEvent,
        fields = ["program::Int"],
        decode = :(Int.(data)),
        encode = :(UInt8.([event.program]))
    ),
    0xD0 => (
        type = :ChannelPressureEvent,
        fields = ["pressure::Int"],
        decode = :(Int.(data)),
        encode = :(UInt8.([event.pressure]))
    ),
    0xE0 => (
        type = :PitchBendEvent,
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
function define_type(type, fields, decode, encode_, supertype, typebyte)
    @eval begin
        mutable struct $type <: $supertype
            dT::Int
            $(fields...)
        end

        """    $($type)(dT::Int, typebyte::UInt8, data::Vector{UInt8})
        Returns a `$($type)` event from it's byte representation.
        The parameter `typebyte::UInt8` is its's $(($type <: MetaEvent) ? "metatype" : "status") byte.
        """
        function $type(dT::Int, typebyte::UInt8, data::Vector{UInt8})
            $type(dT, typebyte, $decode...)
        end

        if $type <: MetaEvent
            @doc """    $($type)(dT::Int, args...)
            Construct a `$($type)` event without specifying the metatype byte.
            """
            function $type(dT::Int, args...)
                length(args) != length(fieldnames($type)) - 2 && throw(MethodError($type, (dT, args...)))
                $type(dT, $typebyte, args...)
            end
        elseif $type <: MIDIEvent
            @doc """    $($type)(dT::Int, args...; channel = 0)
            Construct a `$($type)` event without specifying the status byte.
            The keyword argument `channel` sets the channel for this event.
            """
            function $type(dT::Int, args...; channel = 0)
                length(args) != length(fieldnames($type)) - 2 && throw(MethodError($type, (dT, args...)))
                $type(dT, UInt8($typebyte | channel), args...)
            end
        end

        """    encode(event::$($type))
        Returns the byte representation of a `$($(type))` event.
        """
        function encode(event::$type)
            $encode_
        end
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
        pushfirst!(fields, "status::UInt8")
    else
        supertype = MetaEvent
        if !(0x01 <= typebyte <= 0x07)
            # text-only events already have the metatype field, we don't have to add them
            pushfirst!(fields, "metatype::UInt8")
        end
    end

    # Parse the fields into a Fieldname::Type expression
    fields = Meta.parse.(fields)
    define_type(type, fields, decode, encode, supertype, typebyte)
end

# Create a map from typebyte to the actual types
const MIDI_EVENTS_SPEC = Dict(key => eval(value isa Symbol ? value : value.type) for (key, value) in MIDI_EVENTS_DEFS)

"""    SequenceNumberEvent <: MetaEvent
The `SequenceNumberEvent` contains the number of a sequence
in type 0 and 1 MIDI files, or the pattern number in type 2 MIDI files.

## Fields:
* `dT::Int` : Delta time in ticks.
* `metatype::UInt8` : Meta type byte of the event.
* `number::Int` : Sequence number.
"""
SequenceNumberEvent

"""    TextEvent <: MetaEvent
The `TextEvent` contains a text within the MIDI file.

## Fields:
* `dT::Int` : Delta time in ticks.
* `metatype::UInt8` : Meta type byte of the event.
* `text::String` : The text in the event.
"""
TextEvent

"""    CopyrightNoticeEvent <: MetaEvent
The `CopyrightNoticeEvent` contains a copyright notice
in a MIDI file.

## Fields:
* `dT::Int` : Delta time in ticks.
* `metatype::UInt8` : Meta type byte of the event.
* `text::String` : The copyright notice in text.
"""
CopyrightNoticeEvent

"""    TrackNameEvent <: MetaEvent
The `TrackNameEvent` contains either the name of a MIDI sequence
(when in MIDI type 0 or MIDI type 2 files, or when in the first track of a MIDI type 1 file),
or the name of a MIDI track (when in other tracks of a MIDI type 1 file).

## Fields:
* `dT::Int` : Delta time in ticks.
* `metatype::UInt8` : Meta type byte of the event.
* `text::String` : The track name in text.
"""
TrackNameEvent

"""    InstrumentNameEvent <: MetaEvent
The `InstrumentNameEvent` contains the name of the instrument to be used in a track.

## Fields:
* `dT::Int` : Delta time in ticks.
* `metatype::UInt8` : Meta type byte of the event.
* `text::String` : The instrument name in text.
"""
InstrumentNameEvent

"""    LyricEvent <: MetaEvent
The `LyricEvent` contains the lyrics (usually syllables) in a MIDI file.

## Fields:
* `dT::Int` : Delta time in ticks.
* `metatype::UInt8` : Meta type byte of the event.
* `text::String` : The lyric in text.
"""
LyricEvent

"""    MarkerEvent <: MetaEvent
The `MarkerEvent` contains the text of a marker.

## Fields:
* `dT::Int` : Delta time in ticks.
* `metatype::UInt8` : Meta type byte of the event.
* `text::String` : The marker text.
"""
MarkerEvent

"""    CuePointEvent <: MetaEvent
The `CuePointEvent` contains a cue in a MIDI file.

## Fields:
* `dT::Int` : Delta time in ticks.
* `metatype::UInt8` : Meta type byte of the event.
* `text::String` : The cue in text.
"""
CuePointEvent

"""    MIDIChannelPrefixEvent <: MetaEvent
The `MIDIChannelPrefixEvent` contains a channel number to which
the following meta messages are sent to.

## Fields:
* `dT::Int` : Delta time in ticks.
* `metatype::UInt8` : Meta type byte of the event.
* `channel::Int` : The channel number.
"""
MIDIChannelPrefixEvent

"""    EndOfTrackEvent <: MetaEvent
The `EndOfTrackEvent` denotes the end of a track.

## Fields:
* `dT::Int` : Delta time in ticks.
* `metatype::UInt8` : Meta type byte of the event.
"""
EndOfTrackEvent

"""    SetTempoEvent <: MetaEvent
The `SetTempoEvent` sets the tempo of a MIDI sequence in terms of
microseconds per quarter note.

## Fields:
* `dT::Int` : Delta time in ticks.
* `metatype::UInt8` : Meta type byte of the event.
* `tempo::Int` : The tempo in microseconds per quarter note.
"""
SetTempoEvent

"""    TimeSignatureEvent <: MetaEvent
The `TimeSignatureEvent` contains the time signature of a MIDI sequence.

## Fields:
* `dT::Int` : Delta time in ticks.
* `metatype::UInt8` : Meta type byte of the event.
* `numerator::Int` : Numerator of the time signature.
* `denominator::Int` : Denominator of the time signature.
* `clockticks::Int` : MIDI clock ticks per click.
* `notated32nd_notes::Int` : Number of 32nd notes per beat.
"""
TimeSignatureEvent

"""    KeySignatureEvent <: MetaEvent
The `KeySignatureEvent` contains the key signature and scale of a MIDI file.

## Fields:
* `dT::Int` : Delta time in ticks.
* `metatype::UInt8` : Meta type byte of the event.
* `semitones::Int` : Number of flats or sharps.
* `scale::Int` : Scale of the MIDI file - 0 if the scale is major
   and 1 if the scale is minor.
"""
KeySignatureEvent

"""    NoteOffEvent <: MIDIEvent
The `NoteOffEvent` informs a MIDI device to release a note.

## Fields:
* `dT::Int` : Delta time in ticks.
* `status::UInt8` : The status byte of the event.
* `note::Int` : Note to turn off.
* `velocity::Int` : Velocity of the note.
"""
NoteOffEvent

"""    NoteOnEvent <: MIDIEvent
The `NoteOnEvent` informs a MIDI device to play a note.
A `NoteOnEvent` with 0 velocity acts as a `NoteOffEvent`.

## Fields:
* `dT::Int` : Delta time in ticks.
* `status::UInt8` : The status byte of the event.
* `note::Int` : Note to turn on.
* `velocity::Int` : Velocity of the note.
"""
NoteOnEvent

"""    AftertouchEvent <: MIDIEvent
The `AftertouchEvent` informs a MIDI device to apply pressure to a note.

## Fields:
* `dT::Int` : Delta time in ticks.
* `status::UInt8` : The status byte of the event.
* `note::Int` : Note to apply the pressure to.
* `pressure::Int` : Amount of pressure to be applied.
"""
AftertouchEvent

"""    ControlChangeEvent <: MIDIEvent
The `ControlChangeEvent` informs a MIDI device to change the value of a controller.

## Fields:
* `dT::Int` : Delta time in ticks.
* `status::UInt8` : The status byte of the event.
* `controller::Int` : Controller number.
* `value::Int` : Value received by the controller.
"""
ControlChangeEvent

"""    ProgramChangeEvent <: MIDIEvent
The `ProgramChangeEvent` informs a MIDI device to select a program number
in a specific channel.

## Fields:
* `dT::Int` : Delta time in ticks.
* `status::UInt8` : The status byte of the event.
* `program::Int` : The new program number.
"""
ProgramChangeEvent

"""    ChannelPressureEvent <: MIDIEvent
The `ChannelPressureEvent` informs a MIDI device to apply pressure to a specific channel.

## Fields:
* `dT::Int` : Delta time in ticks.
* `status::UInt8` : The status byte of the event.
* `pressure::Int` : Amount of the pressure to be applied.
"""
ChannelPressureEvent

"""    PitchBendEvent <: MIDIEvent
The `PitchBendEvent` informs a MIDI device to modify the pitch in a specific channel.

## Fields:
* `dT::Int` : Delta time in ticks.
* `status::UInt8` : The status byte of the event.
* `pitch::Int` : Value of the pitch bend.
"""
PitchBendEvent
