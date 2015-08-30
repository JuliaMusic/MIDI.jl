# Midi message types

# Channel voice message identifiers. Only the first four bits matter, the remaining bits indicate the channel
# These should be used as masks with the actual midi event header
const NOTEOFF = 0b10000000
const NOTEON = 0b10010000
const POLYPHONICKEYPRESSURE = 0b10100000
const CONTROLCHANGE = 0b10110000
const PROGRAMCHANGE = 0b11000000
const CHANNELPRESSURE = 0b11010000
const PITCHWHEELCHANGE = 0b11100000

# Event type codes
const META = 0xFF
const SYSEX = 0xF0

# Chunk identifiers. The different parts of the file will start with one of these
const MTHD = "MThd"
const MTRK = "MTrk"

# Number of data bytes following a given midi event type
const EVENTTYPETOLENGTH = [
    NOTEOFF => 2,
    NOTEON => 2,
    POLYPHONICKEYPRESSURE => 2,
    CONTROLCHANGE => 2,
    PROGRAMCHANGE => 1,
    CHANNELPRESSURE => 1,
    PITCHWHEELCHANGE => 2,
]
