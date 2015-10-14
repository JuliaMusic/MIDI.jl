# Fields should be self-explanatory. Position is an absolute time (in ticks) within the track.
# Please note that velocity cannot be higher than 127 (0x7F).
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

const Bs = 0
const C = 0
const Cs = 1
const Db = 1
const D = 2
const Ds = 3
const Eb = 3
const E = 4
const Fb = 4
const Es = 5
const F = 5
const Fs = 6
const Gb = 6
const G = 7
const Gs = 8
const Ab = 8
const A = 9
const As = 10
const Bb = 10
const B = 11
const Cb = 11

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

export Bs, C, Cs, Db, D, Ds, Eb, E, Fb, Es, F, Fs, Gb, G, Gs, Ab, A, As, Bb, B, Cb
