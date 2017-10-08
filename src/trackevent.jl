export TrackEvent

"""
    TrackEvent <: Any
Abstract supertype for all MIDI events.

All track events begin with a variable length time value (see `readvariablelength`)
and must have a field named `dT` which contains it. This number notes after
how many ticks since the last event does the current even takes place.

`MIDIEvent`s then resume with a MIDI channel message
defined in `constants.jl`. They're followed by 1 or 2 bytes, depending on the
channel message (see `EVENTTYPETOLENGTH`). If no valid channel message is identified,
the previous seen channel message is used. After that the MIDI command is encoded.

`MetaEvent`s and `SysexEvent`s both resume with a specific byte (see `constants.jl`).
"""
abstract type TrackEvent end

function dt(e::TrackEvent)
    e.dT
end
