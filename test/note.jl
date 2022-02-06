cd(@__DIR__)

@testset "Notes" begin
    midi = load("doxy.mid")

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
    @test pitch_to_name(name_to_pitch("C")) == "C4"
    @test pitch_to_name(name_to_pitch("Cb")) == "B3"
    @test pitch_to_name(name_to_pitch("G♭")) == "F♯4"
    @test pitch_to_name(name_to_pitch("G♭"); flat=true) == "G♭4"
    @test pitch_to_name(name_to_pitch("Bb7")) == "A♯7"

    n = Note(0, 1, 1, 1)
    @test pitch_to_name(n.pitch) == "C-1"

    @test all([name_to_pitch(pitch_to_name(i)) == i for i in 0:255])
end
@testset "frequency" begin
    tol = 10e-5
    @test pitch_to_hz(3,5)==2
end

@testset "copying notes" begin
    midi = load("doxy.mid")
    notes = getnotes(midi.tracks[4])
    n2 = copy(notes)
    notes[1].pitch = 1
    @test n2[1].pitch ≠ 1
end
