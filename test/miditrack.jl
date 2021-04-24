using MIDI: NOTEON, NOTEOFF

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
        midi = load("doxy.mid")
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

        # save and reopen
        save("changedname.mid",midi)
        midi = load("changedname.mid")
        @test trackname(midi.tracks[2]) == "Overwrite"
        rm("changedname.mid")

        # find name at nonzero position
        meta = deepcopy(midi.tracks[2].events[1])
        deleteat!(midi.tracks[2].events,1)
        addevent!(midi.tracks[2],6666,meta)
        @test trackname(midi.tracks[2]) == "Overwrite"
    end

    @testset "addevent!" begin
        track = MIDI.MIDITrack()

        # generate random positions with doubles
        positions = round.(Int, 100 * rand(120))
        # this is the order they should be added to the track
        tracksort = sortperm(positions)

        # add events to the track, encode the order in which the events are
        # added in the status.
        for (i,pos) in enumerate(positions)
            addevent!(track, pos, MIDIEvent(0, UInt8(i) , UInt8[0x00 , 0x00]))
        end

        # obain positions and adding order from track
        stat = [e.status for e in track.events]
        posi = Vector{UInt}()
        ttime = 0
        for event in track.events
            ttime += event.dT
            push!(posi, ttime)
        end

        # events at correct positions
        @test posi == sort(positions)
        # events in correct order
        @test stat == tracksort

    end

    @testset "addevent_hint!" begin
    track = MIDI.MIDITrack()

    # add some random events using addevent  status = 0 to distinguish from
    # the ones added with the function to be tested
    for i = 1:50
        addevent!(track, round(Int, 100 * rand()), MIDIEvent(0, 0 , UInt8[0x00 , 0x00]))
    end

    # generate random but ascending positions
    posis = sort(round.(Int, 100 * rand(70)))

    # add the new events using addevent_hint!
    # again encode order in status (little boring this time, events are already ordered)
    eventindex = 0
    eventtime = 0
    for (i,pos) in enumerate(posis)
        eventindex, eventtime = MIDI.addevent_hint!(track, pos, MIDIEvent(0, UInt8(i) , UInt8[0x00 , 0x00]), eventindex, eventtime)
    end

    # obtain order and positions of the events added with addevent_hint
    stat = [e.status for e in track.events if e.status != 0]
    posi = Vector{Int}()
    ttime = 0
    for event in track.events
        ttime += event.dT
        if event.status != 0
            push!(posi, ttime)
        end
    end

    # events at correct positions
    @test posi == posis
    # events in correct order
    @test Int.(stat) == collect(1:70)

    end

    @testset "addnotes!" begin

        midi = load("doxy.mid")
        original_track = deepcopy(midi.tracks[2])
        test_track = deepcopy(midi.tracks[2])

        # remove notes from test track
        notes = getnotes(test_track)
        deletes = Vector{Int}()
        for (i,event) in enumerate(test_track.events)
            if isa(event, MIDIEvent) && (event.status & 0xF0) in [NOTEON, NOTEOFF]
                push!(deletes, i)
            end
        end
        deleteat!(test_track.events, deletes)

        # add them again  to the emptied track
        addnotes!(test_track, notes)

        # get the notes of the original and the testing track and compare
        onotes = getnotes(original_track)
        tnotes = getnotes(test_track)
        identical = true
        for i = 1:length(onotes)
            if onotes[i] != tnotes[i]
                identical = false
            end
        end

        @test identical

    end
end
