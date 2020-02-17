export Note, Notes, AbstractNote, DrumNote
export pitch_to_name, name_to_pitch

abstract type AbstractNote end

"""
    Note(pitch, velocity, position, duration, channel = 0) <: AbstractNote
Mutable data structure describing a music note. A bundle of many notes results
in the [`Notes`](@ref) struct, which is the output of the [`getnotes`](@ref)
function.

If the `channel` of the note is `0` (default), it is not shown.

You can also create a `Note` with the following keyword constructor:
```julia
Note(pitch, position; velocity = 100, duration = 960, channel = 0)
```

## Fields:
* `pitch::UInt8` : Pitch, starting from C-1 = 0, adding one per semitone.
  Use the functions [`name_to_pitch`](@ref) and
  [`pitch_to_name`](@ref) for integer and string representations.
* `velocity::UInt8` : Dynamic intensity. Cannot be higher than 127 (0x7F).
* `position::UInt` : Position in absolute time (since beginning of track), in ticks.
* `duration::UInt` : Duration in ticks.
* `channel::UInt8 = 0` : Channel of the track that the note is played on.
  Cannot be higher than 127 (0x7F).
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
Note(pitch, position; velocity = 100, duration = 960, channel = 0) =
Note(pitch, velocity, position, duration, channel)

@inline Note(n::Note) = n

"""
    DrumNote(pitch, position, duration = 960; velocity = 100)
Shorthand constructor for a [`Note`](@ref) that is always on channel `9`.
It is possible to specify pitch as a `String` (e.g. "Acoustic Snare"), which
will be converted to actual pitch using [`DRUMKEY`](@ref).
"""
DrumNote(pitch, position, duration = 960; velocity = 100, gmmap = DRUMKEY) =
Note(_drumpitch(pitch, gmmap), velocity, position, duration, 9)

_drumpitch(pitch::Real, gmmap) = pitch
_drumpitch(pitch::String, gmmap) = name_to_pitch(gmmap[pitch])

import Base.==
==(n1::AbstractNote, n2::AbstractNote) =
    n1.pitch == n2.pitch &&
    n1.duration == n2.duration &&
    n1.position == n2.position &&
    n1.channel == n2.channel &&
    n1.velocity == n2.velocity

Base.copy(n::N) where {N<:AbstractNote} =
N(n.pitch, n.velocity, n.position, n.duration, n.channel)

"""
    Notes(note_vector, tpq = 960) -> Notes
A data structure describing a collection of music notes, bundled with the ticks
per quarter note (so that the notes can be attributed rhythmic value).

`Notes` can be iterated and accessed as the given `note_vector`.
"""
struct Notes{N <: AbstractNote}
    notes::Vector{N}
    tpq::Int16
end

# Constructors for Notes:
function Notes(notes::Vector{N}, tpq::Int = 960) where {N <: AbstractNote}
    if tpq < 1
        throw(ArgumentError("Ticks per quarter note (tpq) must be >= 1"))
    end
    Notes{N}(notes, tpq)
end

Notes(; tpq = 960) = Notes{Note}(Vector{Note}[], tpq)

# Iterator Interface for notes:
Base.iterate(n::Notes, i = 1) = iterate(n.notes, i)
# Base.iterate(n::Notes, i) = iterate(n.notes, i)
Base.eltype(::Type{Notes{N}}) where {N} = N

# Indexing
Base.length(n::Notes) = length(n.notes)
Base.lastindex(n::Notes) = lastindex(n.notes)
Base.firstindex(n::Notes) = firstindex(n.notes)
Base.getindex(n::Notes, i::Int) = n.notes[i]
Base.getindex(n::Notes, r) = Notes(n.notes[r], n.tpq)
Base.view(n::Notes, r) = view(n.notes, r)

# Pushing
Base.push!(no::Notes{N}, n::N) where {N <: AbstractNote} = push!(no.notes, n)
function Base.append!(n1::Notes{N}, n2::Notes{N}) where {N}
    n1.tpq == n2.tpq || throw(ArgumentError("The Notes do not have same tpq."))
    append!(n1.notes, n2.notes)
    return n1
end

Base.copy(notes::Notes) = Notes([copy(n) for n in notes], notes.tpq)


#######################################################
# string name <-> midi pitch
#######################################################
using Base.Meta, Base.Unicode
const PITCH_TO_NAME = Dict(
0=>"C", 1=>"C♯", 2=>"D", 3=>"D♯", 4=>"E", 5=>"F", 6=>"F♯", 7=>"G", 8=>"G♯", 9=>"A",
10 =>"A♯", 11=>"B")
const NAME_TO_PITCH = Dict(
v => k for (v, k) in zip(values(PITCH_TO_NAME), keys(PITCH_TO_NAME)))

"""
    pitch_to_name(pitch) -> string
Return the name of the pitch, e.g. `F5`, `A♯3` etc. in modern notation given the
pitch value in integer.

Reminder: middle C has pitch `60` and is displayed as `C4`.
"""
function pitch_to_name(j)
    i = Int(j)
    notename = PITCH_TO_NAME[mod(i, 12)]
    octave = (i÷12)-1
    return notename*string(octave)
end

"""
    name_to_pitch(p::String) -> Int
Return the pitch value of the given note name `p`, which can be of the form
`capital_letter*sharp*octave` where:

* `capital_letter` : from `"A"` to `"G"`.
* `sharp` : one of `"#"` `"♯"` or `""`.
* `octave` : any integer (as a string), the octave number (an octave is 12 pitches).
  If not given it is assumed `"5"`.

We define E.g. `name_to_pitch("C4") === 60` (i.e. string
`"C4"`, representing the middle-C, corresponds to pitch `60`).

See http://newt.phys.unsw.edu.au/jw/notes.html
and https://en.wikipedia.org/wiki/C_(musical_note) .
"""
function name_to_pitch(p)
    pe = collect(Unicode.graphemes(p))
    pitch = NAME_TO_PITCH[pe[1]]
    x = 0
    if pe[2] == "#" || pe[2] == "♯"
        x = 1
    end
    if length(pe) > 1 + x
        octave = Meta.parse(join(pe[2+x:end]))
    else
        octave = 4
    end

    return pitch + x + 12(octave+1) # lowest possible octave is -1 but pitch starts from 0
end

#######################################################
# pretty printing
#######################################################
function Base.show(io::IO, note::N) where {N<:AbstractNote}
    mprint = nameof(N)
    nn = rpad(pitch_to_name(note.pitch), 3)
    chpr = note.channel == 0 ? "" : " | channel $(note.channel)"
    velprint = rpad("vel = $(Int(note.velocity))", 9)
    print(io, "$(mprint) $nn | $velprint | "*
    "pos = $(Int(note.position)), "*
    "dur = $(Int(note.duration))"*chpr)
end

function Base.show(io::IO, ::MIME"text/plain", notes::Notes{N}) where {N}
    mprint = nameof(N)
    print(io, "$(length(notes)) $(mprint)s with tpq=$(notes.tpq)")
    _notevectorprint(io, notes)
end
function Base.show(io::IO, notes::Vector{N}) where {N<:AbstractNote}
    mprint = nameof(N)
    print(io, "$(length(notes))-element Vector{$mprint}")
    _notevectorprint(io, notes)
end

function _notevectorprint(io, notes)
    s = 7
    if length(notes) > 2s
        for note in (@view notes[1:s])
            print(io, "\n", " ", note)
        end
        print(io, "\n", "  ⋮")
        for note in (@view notes[end-s+1:end])
            print(io, "\n", " ", note)
        end
    else
        for note in notes
            print(io, "\n", " ", note)
        end
    end
end

function Base.show(io::IO, notes::Notes{N}) where {N}
    mprint = nameof(N)
    print(io, "Notes{$(mprint)} with $(length(notes)) notes")
end
