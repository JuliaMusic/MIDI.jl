type Note
    value::Uint8
    duration::Uint64
    position::Uint64
    channel::Uint8
    velocity::Uint8

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

+(n::Note, i::Integer) = Note(n.value + i, n.duration, n.position, n.channel, n.velocity)
+(i::Integer, n::Note) = n + i

-(n::Note, i::Integer) = Note(n.value - i, n.duration, n.position, n.channel, n.velocity)
-(i::Integer, n::Note) = n - i
