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
    G = Midi.Note(67, 96, 48, 0)
    E = Midi.Note(64, 96, 96, 0)
    inc = 96

    file = Midi.MIDIFile()
    track = Midi.MIDITrack()

    notes = Midi.Note[]
    i = 0
    for v in values(GM)
        push!(notes, C)
        push!(notes, E)
        push!(notes, G)
        Midi.programchange(track, E.position + inc + inc, uint8(0), v)
        C.position += inc
        E.position += inc
        G.position += inc
        C = Midi.Note(60, 96, C.position+inc, 0)
        E = Midi.Note(64, 96, E.position+inc, 0)
        G = Midi.Note(67, 96, G.position+inc, 0)
        i += 1
        if i == 3
            break
        end
    end

    Midi.addnotes(track, notes)

    buf = IOBuffer()
    writetrack(buf, track)
    println(track)

    for (n1, n2) in zip(notes, Midi.getnotes(track))
        println("$(n1) == $(n2)")
    end

    push!(file.tracks, track)
    Midi.writemidifile("test_out.mid", file)
end
