cd(@__DIR__)

@testset "Notes" begin
    midi = readMIDIFile("doxy.mid")

    notes = getnotes(midi.tracks[4])

    @test notes.tpq == 960
    @test typeof(notes[1]) == Note
    @test typeof(notes[1:3]) == Notes{Note}
    @test typeof(notes[1:3]) <: Notes
    @test notes[1:3].notes == notes.notes[1:3]
end

@testset "pitch names" begin
    a = ["C5", "D12", "D#3", "G#52","A23"]
    for n in a
        @test n == replace(pitch_to_name(name_to_pitch(n)), "♯" => "#")
    end
    @test pitch_to_name(name_to_pitch("E#7")) == "F7"
    @test pitch_to_name(name_to_pitch("B#")) == "C5"
    @test pitch_to_name(name_to_pitch("F♯")) == "F♯4"
    @test name_to_pitch("C4") == 60

    n = Note(0, 1, 1, 1)
    @test pitch_to_name(n.pitch) == "C-1"
end
