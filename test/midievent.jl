@testset "MIDIEvent" begin
    # test one of each length of status bytes
    statusbytes = [MIDI.NOTEOFF, MIDI.CHANNELPRESSURE];

    @testset "it should test that MIDI events are read and written successfully when status is provided, and when running status is used" begin
        for status_ in statusbytes
            # Structure: dT (variable length), status byte (optional, based on running status), data
            # data length depends on the high nybble of the status byte
            # dT is a variable length value which is handled by readvariablelength and not readMIDIevent. We don't need to test it here, which
            # is why it's set to 0 in each case.
            input = vcat([0x00, status_], zeros(UInt8, MIDI.EVENTTYPETOLENGTH[status_]))
            input_no_status = vcat([0x00], zeros(UInt8, MIDI.EVENTTYPETOLENGTH[status_]))
            type = getfield(MIDI, MIDI.MIDI_EVENTS_SPEC[status_].type)
            output = type(0, 0, zeros(Int, MIDI.EVENTTYPETOLENGTH[status_])...)

            result = MIDI.readMIDIevent(Int(input[1]), IOBuffer(input[2:length(input)]), UInt8(0))
            @test result.dT == output.dT && MIDI.status(result) == status_ && MIDI.encode(result) == MIDI.encode(output)

            result = MIDI.readMIDIevent(Int(input_no_status[1]), IOBuffer(input_no_status[2:length(input_no_status)]), status_)
            @test result.dT == output.dT && MIDI.encode(result) == MIDI.encode(output)

            input, output = output, input
            output_no_status = input_no_status

            buf = IOBuffer()
            MIDI.writeevent(buf, input, true)
            @test take!(buf) == output

            buf = IOBuffer()
            MIDI.writeevent(buf, input, false)
            @test take!(buf) == output_no_status
        end
    end
end
