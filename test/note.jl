@test (Midi.Note(60, 96, 0, 0) + 2).value == 62
@test (Midi.Note(60, 96, 0, 0) - 2).value == 58
@test (Midi.Note(60, 96, 0, 0) + 0).value == 60
