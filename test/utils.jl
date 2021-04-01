cd(@__DIR__)

@testset "Time Signature" begin
    midi = readMIDIFile("doxy.mid")
    @test time_signature(midi) == "4/4"
end

