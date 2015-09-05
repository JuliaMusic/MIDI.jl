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

    C = Midi.Note(60, 96, 0, 0)
    D = Midi.Note(62, 96, 96, 0)
    inc = 96

    file = Midi.MIDIFile()
    track = Midi.MIDITrack()

    notes = Midi.Note[]
    for v in values(GM)
        push!(notes, C)
        push!(notes, D)
        Midi.programchange(track, D.position + inc, uint8(0), v)
        C.position += inc
        D.position += inc
        C = Midi.Note(60, 96, C.position+inc, 0)
        D = Midi.Note(62, 96, D.position+inc, 0)
        break
    end

    Midi.addnotes(track, notes)

    for (n1, n2) in zip(notes, Midi.getnotes(track))
        println("$(n1) == $(n2)")
    end

    push!(file.tracks, track)
    Midi.writemidifile("test_out.mid", file)
end
