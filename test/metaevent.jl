@testset "Metaevent" begin
    validtestvalues = [
        # Structure: dT (variable length), begin byte (0xFF), type byte, length (variable length type), data
        # dT is a variable length value which is handled by readvariablelength and not readsysexevent. We don't need to test it here, which
        # is why it's set to 0 in each case.
        ([0x00, 0xFF, 0x03, 0x04, 0x11, 0x21, 0x53, 0x1F], MIDI.TrackNameEvent(0, 0x03, [0x11, 0x21, 0x53, 0x1F])),
        ([0x00, 0xFF, 0x05, 0x06, 0x25, 0x61, 0x23, 0x5B, 0x00, 0x02], MIDI.LyricEvent(0, 0x05, [0x25, 0x61, 0x23, 0x5B, 0x00, 0x02]))
    ]

    invalidtestvalues = [
        ([0x00, 0xF0, 0x05, 0x11, 0xF7, 0x53, 0x1F], ErrorException)
    ]

    @testset "it should correctly generate a metaevent from raw data" begin
        for (input, output) in validtestvalues
            result = MIDI.readmetaevent(Int(input[1]), IOBuffer(input[2:length(input)]))
            @test result.dT == output.dT && encode(result) == encode(output)
        end
    end

    @testset "it should corrrectly write a MetaEvent to raw data" begin
        for (output, input) in validtestvalues
            buf = IOBuffer()
            MIDI.writeevent(buf, input)
            @test take!(buf) == output
        end
    end

    @testset "it should fail when invalid raw data is provided" begin
        for (input, errtype) in invalidtestvalues
            @test_throws errtype MIDI.readsysexevent(Int(input[1]), IOBuffer(input[2:length(input)]))
        end
    end

    @testset "SequencerSpecificEvent" begin
        midi = load("SequencerSpecific.mid")
        length(getnotes(midi.tracks[1], midi.tpq)) > 0
        
        sse = MIDI.SequencerSpecificEvent(0, 0x7f, [0x11, 0x21, 0x53, 0x1F])
        @test sse.ssdata == [0x11, 0x21, 0x53, 0x1F]
    end
end
