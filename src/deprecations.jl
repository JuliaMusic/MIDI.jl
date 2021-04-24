@deprecate writeMIDIFile(filename::AbstractString, data::MIDIFile) save(File{format"MIDI"}(filename), data)
@deprecate writeMIDIFile(filename::AbstractString, notes::Notes) save(File{format"MIDI"}(filename), notes)
@deprecate readMIDIFile(filename::AbstractString) load(File{format"MIDI"}(filename))
