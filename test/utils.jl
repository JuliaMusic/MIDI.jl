@testset "Utility functions" begin
    midi = load(testmidi())
    @test time_signature(midi) == "4/4"
    @test qpm(midi) ≈ 130.00013
    @test bpm(midi) ≈ 130.00013

    first_tempo_event = tempochanges(midi)[1]
    @test first_tempo_event[1] == 0
    @test first_tempo_event[2] ≈ 130.00013
end


