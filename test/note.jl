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
    tol = 10e-3
    @test pitch_to_hz(69,440)==440
    @test pitch_to_hz(69,432)==432
    @test abs( pitch_to_hz(44)-103.8262 ) < tol
    @test abs(pitch_to_hz(105)-3520.000) < tol
    @test abs(pitch_to_hz(89,432)-1371.51) < tol
    #hz to pitch
    @test hz_to_pitch(440) == 69
    @test hz_to_pitch(432,432) == 69
    @test round(hz_to_pitch(7040.000)) == 117
    @test round(hz_to_pitch(123.4708)) == 47
    

end

@testset "copying notes" begin
    midi = load("doxy.mid")
    notes = getnotes(midi.tracks[4])
    n2 = copy(notes)
    notes[1].pitch = 1
    @test n2[1].pitch ≠ 1
end

@testset "is octave" begin
    n1 = Note(name_to_pitch("C4"),0)
    n2 = Note(name_to_pitch("C5"),1)
    n3 = Note(name_to_pitch("D5"),2)
    @test is_octave(n1,n2)
    @test !is_octave(n1,n3)
end