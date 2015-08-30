type MIDIFile
    format::Uint16
    timedivision::Uint16
    tracks::Array{MIDITrack, 1}

    MIDIFile() = new(0,0,MIDITrack[])
end
