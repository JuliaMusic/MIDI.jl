export Note, Notes

"""
    Note <: Any
Data structure describing a "music note".
## Fields:
* `value::UInt8` : Pitch, starting from C0 = 0, adding one per semitone (middle-C is 60).
* `duration::UInt` : Duration in ticks.
* `position::UInt` : Position in absolute time (since beginning of track), in ticks.
* `channel::UInt8` : Channel of the track that the note is played on.
* `velocity::UInt8` : Dynamic intensity. Cannot be higher than 127 (0x7F).
"""
mutable struct Note
    value::UInt8
    duration::UInt
    position::UInt
    channel::UInt8
    velocity::UInt8

    Note(value, duration, position, channel, velocity=0x7F) =
        if channel > 0x7F
            error( "Channel must be less than 128" )
        elseif velocity > 0x7F
            error( "Velocity must be less than 128" )
        else
            new(value, duration, position, channel, velocity)
        end
end

import Base.+, Base.-, Base.==

+(n::Note, i::Integer) = Note(n.value + i, n.duration, n.position, n.channel, n.velocity)
+(i::Integer, n::Note) = n + i

-(n::Note, i::Integer) = Note(n.value - i, n.duration, n.position, n.channel, n.velocity)
-(i::Integer, n::Note) = n - i

==(n1::Note, n2::Note) =
    n1.value == n2.value &&
    n1.duration == n2.duration &&
    n1.position == n2.position &&
    n1.channel == n2.channel &&
    n1.velocity == n2.velocity

"""
    Notes <: Any
Data structure describing a collection of "music notes", bundled with a ticks
per quarter note measure.
## Fields:
* `notes::Vector{Note}`
* `tpq::Int16` : Ticks per quarter note. Defines the fundamental unit of measurement
   of a note's position and duration, as well as the length of one quarter note.
   Takes values from 1 to 960.

`Notes` is iterated and accessed as if iterating or accessing its field `notes`.
"""
mutable struct Notes
    notes::Vector{Note}
    tpq::Int16
    function Notes(notes, tpq)
        if tpq < 1 || tpq > 960
            throw(ArgumentError("Ticks per quarter note (tpq) must be ∈ [1, 960]"))
        end
        new(notes, tpq)
    end
end

# Constructors for Notes:
Notes(notes::Vector{Note}) = Notes(notes, 960)
Notes() = Notes(Vector{Note}[], 960)

# Iterator Interface for notes:
Base.start(n::Notes) = start(n.notes)
Base.next(n::Notes, i) = next(n.notes, i)
Base.done(n::Notes, i) = done(n.notes, i)

# Indexing
Base.length(n::Notes) = length(n.notes)
Base.endof(n::Notes) = endof(n.notes)
Base.getindex(n::Notes, i) = n.notes[i]
