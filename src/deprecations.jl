@deprecate writeMIDIFile(filename::AbstractString, data::MIDIFile) MIDI.save(filename, data)
@deprecate writeMIDIFile(filename::AbstractString, notes::Notes) MIDI.save(filename, notes)
@deprecate readMIDIFile(filename::AbstractString) MIDI.load(filename)
