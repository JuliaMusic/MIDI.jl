type MetaEvent <: TrackEvent
    dT::Int
    metatype::Uint8
    data::Array{Uint8,1}
end
