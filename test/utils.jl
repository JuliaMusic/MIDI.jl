@testset "Utility functions" begin
    midi = readMIDIFile(testmidi())
    @test time_signature(midi) == "4/4"
    @test qpm(midi) ≈ 130.00013
    @test bpm(midi) ≈ 130.00013
end


