# Functions that find special events, like e.g. lyrics, or tracknames
# are contained here

export trackname, addtrackname!, textevent, findtextevents

"""
    trackname(track::MIDI.MIDITrack)

Return the name of the given `track` as a string,
by finding the "track name" `MetaEvent`.
"""
function trackname(track::MIDI.MIDITrack)

    pos = findtrackname(track)
    if pos == 0
        return "No track name found"
    # check if there really is a name
    elseif length(track.events[pos].data) == 0
        return "No track name found"
    else
        event = track.events[pos]
        # extract the name (string(Char()) takes care of ASCII encoding)
        trackname = string(Char(event.data[1]))
        for c in event.data[2:end]
            trackname *= string(Char(c))
        end
        return trackname
    end
end

"""
    addtrackname!(track::MIDI.MIDITrack, name::String)

Add a name to the given `track` by attaching the
"track name" `MetaEvent` to the start of the `track`.
"""
function addtrackname!(track::MIDI.MIDITrack, name::String)
    # construct fitting name event
    data = UInt8[]
    for i = 1:length(name)
        push!(data, UInt8(name[i]))
    end
    meta = MetaEvent(0,0x03,data)

    # remove existing name
    prev = findtrackname(track)
    if prev != 0
        deleteat!(track.events, prev)
    end

    addevent!(track, 0, meta)
end

function findtrackname(track::MIDI.MIDITrack)
    position = 0
    for (i,event) in enumerate(track.events)
        if isa(event, MIDI.MetaEvent) && event.metatype == 0x03
            position = i
            break
        end
    end
    return position
end



"""
    textevent(eventtype, text)
Create an event using the string `text`.
The `eventtype` can be `:text, :lyric, :marker`, which will create the
appropriate type of `MetaEvent`.

The returned event can be added to a [`MIDITrack`](@ref) via either
[`addevent!`](@ref) or [`addevents!`](@ref) for multiple events.

*Notice* - Cubase can read the marker events and MuseScore can read the lyrics
events. We haven't seen any editor that can read the text events, so far.
"""
function textevent(eventtype, text)
    data = [UInt8(a) for a in text]
    event = MetaEvent(0, s_to_text[eventtype], data)
end

const s_to_text = Dict(
:text => TEXTEV, :lyric => LYRICEV, :marker => MARKEREV
)

"""
    findtextevents(eventtype, track)
Find all "text" events specifield by `eventtype` in the `track`.
The `eventtype` can be `:text, :lyric, :marker`, which will find the
appropriate `MetaEvent`s.

For convenience, this function does not return the events themselves.
Instead, it returns three vectors: the first is the strings of the events,
the second is the indices of the events in the `track` and the third is
the absolute position of the events (since start of `track`).

*Notice* - common music score editors like e.g. MuseScore, GuitarPro, etc., do
not export the lyrics and text information when exporting midi files.
"""
function findtextevents(eventtype, track)
    etype = s_to_text[eventtype]
    events = String[]
    idxs = Int[]
    for (i, event) ∈ enumerate(track.events)
        if typeof(event) == MetaEvent && event.metatype == etype
            # lol without copy the events are lost!
            push!(events, String(copy(event.data)))
            push!(idxs, i)
        end
    end
    length(idxs) == 0 && error("Found no events of such type")
    abspos = get_abs_pos(idxs, track)
    return events, idxs, abspos
end
