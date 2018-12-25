cd(@__DIR__)

@testset "reading negative delta" begin
    midi = readMIDIFile("negative_delta.mid")
    @test midi.tracks[1].events[3].dT == -48
end

@testset "writing negative delta" begin
    stream = IOBuffer()
    @test_throws ErrorException MIDI.writeevent(stream, MIDIEvent(-1, 0x80, [0x00, 0x00]))
    @test_throws ErrorException MIDI.writeevent(stream, MetaEvent(-1, 0x51, [0x00, 0x00, 0x01]))
    @test_throws ErrorException MIDI.writeevent(stream, SysexEvent(-1, [0x01]))
    @test_throws ErrorException MIDI.writevariablelength(stream, -1)
    @test_throws ErrorException MIDI.writevariablelength(stream, Int(0x1FFFFFFF))
    close(stream)
end
