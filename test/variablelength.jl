testvalues = [
    ([UInt8(0b10000001), UInt8(0b00000001)], 0b10000001),
    ([UInt8(0b00001111)], 0b00001111),
    ([UInt8(0b10011001), UInt8(0b00100101)], 0b0000110010100101),
    ([UInt8(0b10000001), UInt8(0b01111111)], 0b11111111)
]

for (input, output) in testvalues
    @test MIDI.readvariablelength(IOBuffer(input)) == output
end

for (output, input) in testvalues
    buf = IOBuffer()
    MIDI.writevariablelength(buf, Int64(input))
    @test takebuf_array(buf) == output
end
