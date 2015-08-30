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
