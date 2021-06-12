# Functions that find special events, like e.g. lyrics, or tracknames
# are contained here

export trackname, addtrackname!, textevent, findtextevents
export tracknames

const NOTRACKNAME = "No track name found"

"""
    trackname(track::MIDI.MIDITrack)

Return the name of the given `track` as a string,
by finding the `TrackName` meta event.

If no such event exists, `"No track name found"` is returned.
"""
function trackname(track::MIDI.MIDITrack)
    for event in track.events
        if event isa TrackName
            return event.text
        end
    end
    return NOTRACKNAME
end

"`tracknames(m::MIDIFile) = trackname.(m.tracks)`"
tracknames(m::MIDIFile) = trackname.(m.tracks)

"""
    addtrackname!(track::MIDI.MIDITrack, name::String)

Add a name to the given `track` by attaching the
`TrackName` meta event to the start of the `track`.
"""
function addtrackname!(track::MIDI.MIDITrack, name::String)
    trackname = TrackName(0, name)

    # Remove existing name
    for (i, event) in enumerate(track.events)
        if event isa TrackName
            deleteat!(track.events, i)
            break
        end
    end

    addevent!(track, 0, trackname)
end


"""
    findtextevents(eventtype, track)
Find all text events specifield by `eventtype` in the `track`.
The `eventtype` can be `TextEvent, Lyric, Marker, which will find the
appropriate meta events.

For convenience, this function does not return the events themselves.
Instead, it returns three vectors: the first is the strings of the events,
the second is the indices of the events in the `track` and the third is
the absolute position of the events (since start of `track`).

*Notice* - common music score editors like e.g. MuseScore, GuitarPro, etc., do
not export the lyrics and text information when exporting midi files.

*Notice* - Cubase can read the marker events and MuseScore can read the lyrics
events. We haven't seen any editor that can read the text events, so far.
"""
function findtextevents(eventtype, track)
    events = String[]
    idxs = Int[]
    for (i, event) ∈ enumerate(track.events)
        if event isa eventtype
            # lol without copy the events are lost!
            push!(events, String(copy(event.data)))
            push!(idxs, i)
        end
    end
    length(idxs) == 0 && error("Found no events of such type")
    abspos = get_abs_pos(idxs, track)
    return events, idxs, abspos
end
