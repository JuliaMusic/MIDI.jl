statusbytes = [0x80, 0x90, 0xA0, 0xB0, 0xC0, 0xD0, 0xE0]

for status in statusbytes
    # Structure: dT (variable length), status byte (optional, based on running status), data
    # data length depends on the high nybble of the status byte
    # dT is a variable length value which is handled by readvariablelength and not readMIDIevent. We don't need to test it here, which
    # is why it's set to 0 in each case.
    input = vcat([0x00, status], zeros(UInt8, MIDI.EVENTTYPETOLENGTH[status]))
    input_no_status = vcat([0x00], zeros(UInt8, MIDI.EVENTTYPETOLENGTH[status]))
    output = MIDI.MIDIEvent(0, status, zeros(UInt8, MIDI.EVENTTYPETOLENGTH[status]))

    result = MIDI.readMIDIevent(Int64(input[1]), IOBuffer(input[2:length(input)]), UInt8(0))
    @test result.dT == output.dT && result.status == status && result.data == output.data

    result = MIDI.readMIDIevent(Int64(input_no_status[1]), IOBuffer(input_no_status[2:length(input_no_status)]), status)
    @test result.dT == output.dT && result.data == output.data

    # Test writing
    input, output = output, input
    output_no_status = input_no_status

    buf = IOBuffer()
    MIDI.writeevent(buf, input, true)
    @test takebuf_array(buf) == output

    buf = IOBuffer()
    MIDI.writeevent(buf, input, false)
    @test takebuf_array(buf) == output_no_status
end
