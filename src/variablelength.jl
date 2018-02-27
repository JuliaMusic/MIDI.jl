export readvariablelength, writevariablelength
"""
    readvariablelength(f::IO)
Variable length numbers in MIDI files are represented as a sequence of bytes.
If the first bit is 0, we're looking at the last byte in the sequence. The remaining
7 bits indicate the number.
"""
function readvariablelength(f::IO)

    mask = 0b10000000
    notmask = ~mask
    # Read the first byte
    b = read(f, UInt8)
    bytes = UInt8[]
    if (b & mask) == 0
        # We're done here. The first bit isn't set, so the number is contained in the 7 remaining bits.
        convert(Int, b)
    else
        result = convert(UInt32, 0)
        while (b & mask) == mask
            result <<= 7
            result += (b & notmask)
            b = read(f, UInt8)
        end
        result = (result << 7) + b # No need to "& notmask", since the most significant bit is 0
        Int(reinterpret(Int32,result))
    end
end


"""
    writevariablelength(f::IO, number::Int)
Write on `f` the given `number`, firstly converting it to the "variable length" format.
See the documentation for more.
"""
function writevariablelength(f::IO, number::Int)
    if number < 128
        write(f, UInt8(number))
    else
        bytes = UInt8[]

        push!(bytes, UInt8(number & 0x7F)) # Get the bottom 7 bits
        number >>>= 7 # Is there a bug with Julia here? Testing in the REPL on negative numbers give >> and >>> the same result
        while number > 0
            push!(bytes, UInt8(((number & 0x7F) | 0x80)))
            number >>>= 7
            continuation = 0x80
        end
        reverse!(bytes)
        for b in bytes
            write(f, b)
        end
    end
end
