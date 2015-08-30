function readvariablelength(f::IOStream)
    #=
    Variable length numbers in midi files are represented as a sequence of bytes.
    If the first bit is 0, we're looking at the last byte in the sequence. The remaining
    7 bits indicate the number.
    =#
    mask = 0b10000000
    notmask = ~mask
    # Read the first byte
    b = read(f, Uint8)
    bytes = Uint8[]
    if (b & mask) == 0
        # We're done here. The first bit isn't set, so the number is contained in the 7 remaining bits.
        convert(Int64, b)
    else
        result = convert(Int64, 0)
        while (b & mask) == mask
            result <<= 7
            result += (b & notmask)
            b = read(f, Uint8)
        end
        result = (result << 7) + b # No need to "& notmask", since the most significant bit is 0
        result
    end
end

function writevariablelength(f::IOStream, number::Int64)
    if number < 128
        write(f, uint8(number))
    else
        bytes = Uint8[]

        push!(bytes, uint8(number & 0x7F)) # Get the bottom 7 bits
        number >>>= 7 # Is there a bug with Julia here? Testing in the REPL on negative numbers give >> and >>> the same result
        while number > 0
            push!(bytes, uint8(((number & 0x7F) | 0x80)))
            number >>>= 7
            continuation = 0x80
        end
        reverse!(bytes)
        for b in bytes
            write(f, b)
        end
    end
end

function isstatusbyte(b::Uint8)
    (b & 0b10000000) == 0b10000000
end

function isdatabyte(b::Uint8)
    !isstatusbyte(b)
end

function ismetaevent(b::Uint8)
    b == 0xFF
end

function issysexevent(b::Uint8)
    b == 0xF0
end

function ismidievent(b::Uint8)
    !ismetaevent(b) && !issysexevent(b)
end

laststatus = 0
function readmidievent(dT::Int64, f::IOStream)
    data = Uint8[]

    statusbyte = read(f, Uint8)
    highnybble = statusbyte & 0b11110000
    global laststatus

    toread = 0
    if haskey(EVENTTYPETOLENGTH, highnybble)
        laststatus = statusbyte
        toread = EVENTTYPETOLENGTH[highnybble]
    else # Running status is in use
        toread = EVENTTYPETOLENGTH[laststatus & 0b11110000]
        statusbyte = laststatus
        skip(f, -1)
    end

    bytecount = 0

    while bytecount < toread
        b = read(f, Uint8)
        push!(data, b)

        bytecount += 1
    end

    MIDIEvent(dT, statusbyte, data)
end

function writeevent(f::IOStream, event::MIDIEvent, status::Uint8)
    writevariablelength(f, event.dT)

    if status == 0
        write(f, event.status)
    end

    for b in event.data
        write(f, b)
    end
end

function writeevent(f::IOStream, event::MIDIEvent)
    writeevent(f, event, uint8(0))
end

function readmetaevent(dT::Int64, f::IOStream)
    # Meta events are 0xFF - type (1 byte) - variable length data length - data bytes
    skip(f, 1) # Skip the 0xff that starts the event
    data = Uint8[]
    metatype = read(f, Uint8)
    datalength = readvariablelength(f)
    bytecount = 0
    while bytecount < datalength
        b = read(f, Uint8)
        push!(data, b)
        bytecount += 1
    end

    MetaEvent(dT, metatype, data)
end

function writeevent(f::IOStream, event::MetaEvent)
    writevariablelength(f, event.dT)
    write(f, META)
    write(f, event.metatype)
    writevariablelength(f, convert(Int64, length(event.data)))
    for b in event.data
        write(f, b)
    end
end

function readsysexevent(dT::Uint8, f::IOStream)
    data = Uint8[]
    statusbyte = read(f, Uint8)
    b = read(f, Uint8)
    while isdatabyte(b)
        push!(data, b)
        if eof(f)
            return SysexEvent(dT, statusbyte, data)
        end
        b = read(f, Uint8)
    end
    skip(f, -1)

    SysexEvent(dT, statusbyte, data)
end

function writeevent(f::IOStream, event::SysexEvent)
    write(f, SYSEX)
    writevariablelength(f, event.dT)
    write(f, event.status)
    for b in event.data
        write(f, b)
    end
end

function readtrack(f::IOStream)
    mtrk = join(map(char, read(f, Uint8, 4)))
    if mtrk != MTRK
        error("Not a valid midi file. Expected MTrk, got $(mtrk) starting at byte $(hex(position(f)-4, 2))")
    end
    track = MIDITrack()

    # Get the length in bytes of the track
    track.length = ntoh(read(f, Uint32))

    trackstart = position(f)
    bytesread = 0
    while bytesread < track.length
        # A track is made up of events. All events start with a variable length
        # value indicating the number of ticks (time) since the last event.

        # Get the time offset of the next event
        dT = readvariablelength(f)

        # Figure out the event type
        # Remember, endianness is byte order, not bit order. No need to ntoh here.
        event_start = read(f, Uint8)
        skip(f, -1)

        local event
        if ismidievent(event_start)
            event = readmidievent(dT, f)
        elseif issysexevent(event_start)
            event = readsysexevent(dT, f)
        elseif ismetaevent(event_start)
            event = readmetaevent(dT, f)
        else
            error("Unrecognized event $(hex(event_start,2))")
        end
        push!(track.events, event)

        bytesread = position(f) - trackstart
    end

    track
end

function writetrack(f::IOStream, track::MIDITrack)
    write(f, convert(Array{Uint8, 1}, MTRK)) # Track identifier
    write(f, hton(track.length))

    writingmidi = false
    previous_status = uint8(0)

    for event in track.events
        if ismidievent(event) && previous_status != 0 && previous_status == event.status
            writeevent(f, event, previous_status)
        elseif ismidievent(event)
            writeevent(f, event)
            previous_status = event.status
        else
            writeevent(f, event)
            previous_status = uint8(uint8(0) )
        end
    end
end

function channelnumber(m::MIDIEvent)
    0x0F & m.status
end

function dt(e::TrackEvent)
    e.dT
end

function comparefiles(n1, n2)
    f1 = open(n1)
    f2 = open(n2)

    while !eof(f1) && !eof(f2)
        if read(f1, Uint8) != read(f2, Uint8)
            error( "Files diverge at byte $(hex(position(f1)))")
        end
    end
    println( "No differences")
end

function test()
    include("midi.jl")

    f = readmidifile("test.mid")
    writemidifile("test_out.mid", f)

    comparefiles("test.mid", "test_out.mid")

    f = readmidifile("test2.mid")
    writemidifile("test_out.mid", f)

    comparefiles("test2.mid", "test_out.mid")

    f = readmidifile("test3.mid")
    writemidifile("test_out.mid", f)

    comparefiles("test3.mid", "test_out.mid")

    f = readmidifile("test4.mid")
    writemidifile("test_out.mid", f)

    comparefiles("test4.mid", "test_out.mid")

end
