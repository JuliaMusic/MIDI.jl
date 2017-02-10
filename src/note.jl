export Note

"""
    Note <: Any
Data structure describing a "music note".
## Fields:
* `value::UInt8` : Pitch, starting from C0 = 0, adding one per semitone (middle-C is 60).
* `duration::UInt64` : Duration in ticks.
* `position::UInt64` : Position in absolute time (since beginning of track), in ticks.
* `channel::UInt8` : Channel of the track that the note is played on.
* `velocity::UInt8` : Dynamic intensity. Cannot be higher than 127 (0x7F).
"""
type Note
    value::UInt8
    duration::UInt64
    position::UInt64
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
