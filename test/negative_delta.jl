cd(@__DIR__)

@testset "negative delta" begin
    midi = readMIDIfile("negative_delta.mid")
    @test midi.tracks[1].events[3].dT == -48
end
