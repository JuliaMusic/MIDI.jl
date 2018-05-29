validtestvalues = [ # Raw data and the miditrack it should be read into
    # Structure: MTrk, length in bytes (4 bytes long), data
    # Perhaps longer than it needs to be, but covers meta events, MIDI events, and running statuses.
    (
        [0x4d, 0x54, 0x72, 0x6b, 0x00, 0x00, 0x00, 0x52, 0x60, 0x90, 0x3c, 0x7f, 0x30, 0x43, 0x7f, 0x30, 0x80, 0x3c, 0x7f, 0x00, 0x90, 0x40, 0x7f, 0x30, 0x80, 0x43, 0x7f, 0x30, 0xc0, 0x3f, 0x00, 0x80, 0x40, 0x7f, 0x00, 0x90, 0x3c, 0x7f, 0x30, 0x43, 0x7f, 0x30, 0x80, 0x3c, 0x7f, 0x00, 0x90, 0x40, 0x7f, 0x30, 0x80, 0x43, 0x7f, 0x30, 0xc0, 0x22, 0x00, 0x80, 0x40, 0x7f, 0x00, 0x90, 0x3c, 0x7f, 0x30, 0x43, 0x7f, 0x30, 0x80, 0x3c, 0x7f, 0x00, 0x90, 0x40, 0x7f, 0x30, 0x80, 0x43, 0x7f, 0x30, 0xc0, 0x52, 0x00, 0x80, 0x40, 0x7f, 0x00, 0xff, 0x2f, 0x00],
        MIDI.MIDITrack(MIDI.TrackEvent[MIDI.MIDIEvent(96,0x90,UInt8[60,127]),MIDI.MIDIEvent(48,0x90,UInt8[67,127]),MIDI.MIDIEvent(48,0x80,UInt8[60,127]),MIDI.MIDIEvent(0,0x90,UInt8[64,127]),MIDI.MIDIEvent(48,0x80,UInt8[67,127]),MIDI.MIDIEvent(48,0xc0,UInt8[63]),MIDI.MIDIEvent(0,0x80,UInt8[64,127]),MIDI.MIDIEvent(0,0x90,UInt8[60,127]),MIDI.MIDIEvent(48,0x90,UInt8[67,127]),MIDI.MIDIEvent(48,0x80,UInt8[60,127]),MIDI.MIDIEvent(0,0x90,UInt8[64,127]),MIDI.MIDIEvent(48,0x80,UInt8[67,127]),MIDI.MIDIEvent(48,0xc0,UInt8[34]),MIDI.MIDIEvent(0,0x80,UInt8[64,127]),MIDI.MIDIEvent(0,0x90,UInt8[60,127]),MIDI.MIDIEvent(48,0x90,UInt8[67,127]),MIDI.MIDIEvent(48,0x80,UInt8[60,127]),MIDI.MIDIEvent(0,0x90,UInt8[64,127]),MIDI.MIDIEvent(48,0x80,UInt8[67,127]),MIDI.MIDIEvent(48,0xc0,UInt8[82]),MIDI.MIDIEvent(0,0x80,UInt8[64,127])])
    ),
]

invalidtestvalues = [
    ([0x00], EOFError),
    ([0x4d, 0x54, 0x72, 0x6b, 0x00, 0x00, 0x00, 0xFF, 0x00], EOFError),
    ([0x4d, 0x54, 0x72, 0x6b], EOFError),
    ([0x4d, 0x54, 0x72, 0x6c], ErrorException),
]

@testset "MIDITrack" begin
    @testset "Verify that track is read correctly" begin
        for (input, output) in validtestvalues
            result = MIDI.readtrack(IOBuffer(input))
            @test length(result.events) == length(output.events)
            for (e1, e2) in zip(result.events, output.events)
                e1 == e2
            end
        end
    end

    @testset "Successfully write a track" begin
        for (output, input) in validtestvalues
            buf = IOBuffer()
            MIDI.writetrack(buf, input)
            @test take!(buf) == output
        end
    end

    @testset "Fail when invalid track data is provided" begin
        for (input, errtype) in invalidtestvalues
            @test_throws errtype MIDI.readtrack(IOBuffer(input))
        end
    end

    C = MIDI.Note(60, 96, 0, 5)
    G = MIDI.Note(67, 96, 48, 5)
    E = MIDI.Note(64, 96, 96, 5)
    # Test writing notes and program change events to a track
    inc = 96
    track = MIDI.MIDITrack()
    notes = MIDI.Note[]
    for v in UInt8[1,2,3]
        push!(notes, C)
        push!(notes, E)
        push!(notes, G)
        MIDI.programchange(track, E.position + inc + inc, UInt8(0), v)
        C.position += inc
        E.position += inc
        G.position += inc
        C = MIDI.Note(60, 96, C.position+inc, 0)
        E = MIDI.Note(64, 96, E.position+inc, 0)
        G = MIDI.Note(67, 96, G.position+inc, 0)
    end

    MIDI.addnotes!(track, notes)

    # @testset "Allow notes and program change events" begin
    #     buf = IOBuffer()
    #     MIDI.writetrack(buf, track)
    #     @test take!(buf) == [0x4d, 0x54, 0x72, 0x6b, 0x00, 0x00, 0x00, 0x52, 0x60, 0x90, 0x3c, 0x7f, 0x30, 0x43, 0x7f, 0x30, 0x80, 0x3c, 0x7f, 0x00, 0x90, 0x40, 0x7f, 0x30, 0x80, 0x43, 0x7f, 0x30, 0xc0, 0x00, 0x00, 0x80, 0x40, 0x7f, 0x00, 0x90, 0x3c, 0x7f, 0x30, 0x43, 0x7f, 0x30, 0x80, 0x3c, 0x7f, 0x00, 0x90, 0x40, 0x7f, 0x30, 0x80, 0x43, 0x7f, 0x30, 0xc0, 0x01, 0x00, 0x80, 0x40, 0x7f, 0x00, 0x90, 0x3c, 0x7f, 0x30, 0x43, 0x7f, 0x30, 0x80, 0x3c, 0x7f, 0x00, 0x90, 0x40, 0x7f, 0x30, 0x80, 0x43, 0x7f, 0x30, 0xc0, 0x02, 0x00, 0x80, 0x40, 0x7f, 0x00, 0xff, 0x2f, 0x00]
    # end

    @testset "Correctly get notes from a track" begin
        sort!(notes, lt=((x, y)->x.position<y.position))
        for (n1, n2) in zip(notes, MIDI.getnotes(track))
            @test n1 == n2
        end
    end

    @testset "Track names" begin

        # correct tracks
        midi = readMIDIfile("doxy.mid")
        @test trackname(midi.tracks[2]) == "Drums"
        @test trackname(midi.tracks[3]) == "Bass"
        @test trackname(midi.tracks[4]) == "ORIGINAL"

        # broken track
        midi.tracks[2].events = midi.tracks[2].events[10:end]
        @test trackname(midi.tracks[2]) == "No track name found"

        # add track name
        addtrackname!(midi.tracks[2],"Uagadugu")
        @test trackname(midi.tracks[2]) == "Uagadugu"

        # replace track name
        addtrackname!(midi.tracks[2],"Overwrite")
        @test trackname(midi.tracks[2]) == "Overwrite"
    end
end
