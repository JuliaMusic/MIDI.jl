function readvariablelength(f::IO)
    #=
    Variable length numbers in MIDI files are represented as a sequence of bytes.
    If the first bit is 0, we're looking at the last byte in the sequence. The remaining
    7 bits indicate the number.
    =#
    mask = 0b10000000
    notmask = ~mask
    # Read the first byte
    b = read(f, UInt8)
    bytes = UInt8[]
    if (b & mask) == 0
        # We're done here. The first bit isn't set, so the number is contained in the 7 remaining bits.
        convert(Int64, b)
    else
        result = convert(Int64, 0)
        while (b & mask) == mask
            result <<= 7
            result += (b & notmask)
            b = read(f, UInt8)
        end
        result = (result << 7) + b # No need to "& notmask", since the most significant bit is 0
        result
    end
end

function writevariablelength(f::IO, number::Int64)
    if number < 128
        write(f, uint8(number))
    else
        bytes = UInt8[]

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
