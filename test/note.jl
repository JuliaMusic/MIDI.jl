@testset "Note" begin
    @testset "it should correctly get the value of a note after we perform basic arithmetic to it" begin
        @test (MIDI.Note(60, 96, 0, 0) + 2).value == 62
        @test (MIDI.Note(60, 96, 0, 0) - 2).value == 58
        @test (MIDI.Note(60, 96, 0, 0) + 0).value == 60
    end
end
