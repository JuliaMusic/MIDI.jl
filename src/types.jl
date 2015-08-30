#=
All track events begin with a variable length time value (see readvariablelength in util.jl).
Midi events start with a midi channel message defined in constants.jl. They're followed by 1 or 2 bytes, depending on the
channel message (see eventtypetolength). If no valid channel message is identified, the previous seen channel message is used.
Meta events and sysex events both begin with a specific byte (see constants.jl)
=#

type MetaEvent <: TrackEvent
    dT::Int
    metatype::Uint8
    data::Array{Uint8,1}
end

type SysexEvent <: TrackEvent
    dT::Int
    status::Uint8
    data::Array{Uint8,1}
end

function ismidievent(e::MIDIEvent)
    true
end

function ismidievent(Any)
    false
end

#=
Track chunks begin with four bytes spelling out "MTrk", followed by the length
in bytes of the track (see readvariablelength in util.jl), followed by a sequence
of events.
=#

type MIDITrack
    events::Array{TrackEvent, 1}
    length::Uint32

    MIDITrack() = new(
        TrackEvent[],
        0
    )
end

type MIDIFile
    format::Uint16
    timedivision::Uint16
    tracks::Array{MIDITrack, 1}

    MIDIFile() = new(0,0,MIDITrack[])
end

export TrackEvent, MIDIEvent, MetaEvent, SysexEvent, MIDITrack, MIDIFile
