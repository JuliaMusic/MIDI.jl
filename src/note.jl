export Note, Notes, AbstractNote
abstract type AbstractNote end

"""
    Note <: AbstractNote
Data structure describing a "music note".
## Fields:
* `pitch::UInt8` : Pitch, starting from C0 = 0, adding one per semitone
  (middle-C is 60).
* `velocity::UInt8` : Dynamic intensity. Cannot be higher than 127 (0x7F).
* `position::UInt` : Position in absolute time (since beginning of track), in ticks.
* `duration::UInt` : Duration in ticks.
* `channel::UInt8 = 0` : Channel of the track that the note is played on.
  Cannot be higher than 127 (0x7F).

If the `channel` of the note is `0` (default) it is not printed with `show`.
"""
mutable struct Note <: AbstractNote
    pitch::UInt8
    velocity::UInt8
    position::UInt
    duration::UInt
    channel::UInt8

    Note(pitch, velocity, position, duration, channel = 0) =
        if channel > 0x7F
            error( "Channel must be less than 128" )
        elseif velocity > 0x7F
            error( "Velocity must be less than 128" )
        else
            new(pitch, velocity, position, duration, channel)
        end
end
@inline Note(n::Note) = n

import Base.+, Base.-, Base.==

+(n::Note, i::Integer) = Note(n.pitch + i, n.duration, n.position, n.channel, n.velocity)
+(i::Integer, n::Note) = n + i

-(n::Note, i::Integer) = Note(n.pitch - i, n.duration, n.position, n.channel, n.velocity)
-(i::Integer, n::Note) = n - i

==(n1::Note, n2::Note) =
    n1.pitch == n2.pitch &&
    n1.duration == n2.duration &&
    n1.position == n2.position &&
    n1.channel == n2.channel &&
    n1.velocity == n2.velocity

"""
    Notes{N<:AbstractNote}
Data structure describing a collection of "music notes", bundled with a ticks
per quarter note measure.
## Fields:
* `notes::Vector{N}`
* `tpq::Int16` : Ticks per quarter note. Defines the fundamental unit of measurement
   of a note's position and duration, as well as the length of one quarter note.
   Takes pitchs from 1 to 960.

`Notes` is iterated and accessed as if iterating or accessing its field `notes`.
"""
struct Notes{N <: AbstractNote}
    notes::Vector{N}
    tpq::Int16
end

# Constructors for Notes:
function Notes(notes::Vector{N}, tpq::Int = 960) where {N <: AbstractNote}
    if tpq < 1 || tpq > 960
        throw(ArgumentError("Ticks per quarter note (tpq) must ∈ [1, 960]"))
    end
    Notes{N}(notes, tpq)
end

Notes() = Notes{Note}(Vector{Note}[], 960)

# Iterator Interface for notes:
Base.iterate(n::Notes) = iterate(n.notes)
Base.iterate(n::Notes, i) = iterate(n.notes, i)
Base.eltype(::Type{Notes{N}}) where {N} = N

# Indexing
Base.length(n::Notes) = length(n.notes)
Base.lastindex(n::Notes) = lastindex(n.notes)
Base.firstindex(n::Notes) = firstindex(n.notes)
Base.getindex(n::Notes, i::Int) = n.notes[i]
Base.getindex(n::Notes, r) = Notes(n.notes[r], n.tpq)

# Pushing
Base.push!(no::Notes{N}, n::N) where {N <: AbstractNote} = push!(no.notes, n)
function Base.append!(n1::Notes{N}, n2::Notes{N}) where {N}
    n1.tpq == n2.tpq || throw(ArgumentError("The Notes do not have same tpq."))
    append!(n1.notes, n2.notes)
    return n1
end

# Pretty printing
const notenames = Dict(
0=>"C", 1=>"C♯", 2=>"D", 3=>"D♯", 4=>"E", 5=>"F", 6=>"F♯", 7=>"G", 8=>"G♯", 9=>"A",
10 =>"A♯", 11=>"B")

"""
    pitchname(pitch) -> string
Return the name of the pitch, e.g. `F5`, `A♯5` etc. in modern notation given the
value in integer.
"""
function pitchname(i)
    notename = notenames[mod(i, 12)]
    octave = i÷12
    return notename*string(octave)
end

function Base.show(io::IO, note::N) where {N<:AbstractNote}
    mprint = nameof(N)
    nn = rpad(pitchname(note.pitch), 4)
    chpr = note.channel == 0 ? "" : " | channel $(note.channel)"
    velprint = rpad("vel = $(Int(note.velocity))", 9)
    print(io, "$(mprint) $nn | $velprint | "*
    "pos = $(Int(note.position)), "*
    "dur = $(Int(note.duration))"*chpr)
end

function Base.show(io::IO, notes::Notes{N}) where {N}
    mprint = nameof(N)
    print(io, "$(length(notes)) $(mprint)s with tpq=$(notes.tpq)")
    i = 1
    while i ≤ min(10, length(notes))
        print(io, "\n", " ", notes[i])
        i += 1
    end
    if length(notes) > 10
        print(io, "\n", "  ⋮")
    end
end
