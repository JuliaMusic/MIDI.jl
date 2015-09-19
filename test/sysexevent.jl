validtestvalues = [
    # Structure: dT (variable length), begin byte (0xF0), length (variable length type), data, end byte (0xF7)
    # dT is a variable length value which is handled by readvariablelength and not readsysexevent. We don't need to test it here, which
    # is why it's set to 0 in each case.
    ([0x00, 0xF0, 0x05, 0x11, 0x21, 0x53, 0x1F, 0xF7], MIDI.SysexEvent(0, [0x11, 0x21, 0x53, 0x1F])),
    ([0x00, 0xF0, 0x07, 0x25, 0x61, 0x23, 0x5B, 0x00, 0x02, 0xF7], MIDI.SysexEvent(0, [0x25, 0x61, 0x23, 0x5B, 0x00, 0x02]))
]

invalidtestvalues = [
    ([0x00, 0xF0, 0x05, 0x11, 0xF7, 0x53, 0x1F, 0xF7], ErrorException),
    ([0x00, 0xF0, 0x01, 0x11, 0xF7, 0x53, 0x1F, 0xF7], ErrorException)
]

for (input, output) in validtestvalues
    result = MIDI.readsysexevent(input[1], IOBuffer(input[2:length(input)]))
    @test result.dT == output.dT && result.data == output.data
end

for (output, input) in validtestvalues
    buf = IOBuffer()
    MIDI.writeevent(buf, input)
    @test takebuf_array(buf) == output
end

for (input, errtype) in invalidtestvalues
    @test_throws errtype MIDI.readsysexevent(input[1], IOBuffer(input[2:length(input)]))
end
