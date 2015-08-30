type MIDIEvent <: TrackEvent
    dT::Int
    status::Uint8
    data::Array{Uint8,1}
end
