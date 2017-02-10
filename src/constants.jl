# MIDI message types

# Channel voice message identifiers. Only the first four bits matter, the remaining bits indicate the channel
# These should be used as masks with the actual MIDI event header
const NOTEOFF = 0x80
const NOTEON = 0x90
const POLYPHONICKEYPRESSURE = 0xA0
const CONTROLCHANGE = 0xB0
const PROGRAMCHANGE = 0xC0
const CHANNELPRESSURE = 0xD0
const PITCHWHEELCHANGE = 0xE0

# Event type codes
const META = 0xFF
const SYSEX = 0xF0

# Meta event types
const METATRACKEND = 0x2F

# Chunk identifiers. The different parts of the file will start with one of these
const MTHD = "MThd"
const MTRK = "MTrk"

# Number of data bytes following a given MIDI event type
const EVENTTYPETOLENGTH = Dict(
    NOTEOFF => 2,
    NOTEON => 2,
    POLYPHONICKEYPRESSURE => 2,
    CONTROLCHANGE => 2,
    PROGRAMCHANGE => 1,
    CHANNELPRESSURE => 1,
    PITCHWHEELCHANGE => 2,
)

"""
A dictionary that maps an instrument name (type `String`)
to their hex value (type `UInt8`).
"""
const GM = Dict(
    "AcousticGrandPiano" => UInt8(1),
    "BrightAcousticPiano" => UInt8(2),
    "ElectricGrandPiano" => UInt8(3),
    "HonkytonkPiano" => UInt8(4),
    "ElectricPiano1" => UInt8(5),
    "ElectricPiano2" => UInt8(6),
    "Harpsichord" => UInt8(7),
    "Clavi" => UInt8(8),
    "Celesta" => UInt8(9),
    "Glockenspiel" => UInt8(10),
    "MusicBox" => UInt8(11),
    "Vibraphone" => UInt8(12),
    "Marimba" => UInt8(13),
    "Xylophone" => UInt8(14),
    "TubularBells" => UInt8(15),
    "Dulcimer" => UInt8(16),
    "DrawbarOrgan" => UInt8(17),
    "PercussiveOrgan" => UInt8(18),
    "RockOrgan" => UInt8(19),
    "ChurchOrgan" => UInt8(20),
    "ReedOrgan" => UInt8(21),
    "Accordion" => UInt8(22),
    "Harmonica" => UInt8(23),
    "TangoAccordion" => UInt8(24),
    "AcousticGuitarNylon" => UInt8(25),
    "AcousticGuitarSteel" => UInt8(26),
    "ElectricGuitarJazz" => UInt8(27),
    "ElectricGuitarClean" => UInt8(28),
    "ElectricGuitarMuted" => UInt8(29),
    "OverdrivenGuitar" => UInt8(30),
    "DistortionGuitar" => UInt8(31),
    "GuitarHarmonics" => UInt8(32),
    "AcousticBass" => UInt8(33),
    "ElectricBassFinger" => UInt8(34),
    "ElectricBassPick" => UInt8(35),
    "FretlessBass" => UInt8(36),
    "SlapBass1" => UInt8(37),
    "SlapBass2" => UInt8(38),
    "SynthBass1" => UInt8(39),
    "SynthBass2" => UInt8(40),
    "Violin" => UInt8(41),
    "Viola" => UInt8(42),
    "Cello" => UInt8(43),
    "Contrabass" => UInt8(44),
    "TremoloStrings" => UInt8(45),
    "PizzicatoStrings" => UInt8(46),
    "OrchestralHarp" => UInt8(47),
    "Timpani" => UInt8(48),
    "StringEnsemble1" => UInt8(49),
    "StringEnsemble2" => UInt8(50),
    "SynthStrings1" => UInt8(51),
    "SynthStrings2" => UInt8(52),
    "ChoirAahs" => UInt8(53),
    "VoiceOohs" => UInt8(54),
    "SynthVoice" => UInt8(55),
    "OrchestraHit" => UInt8(56),
    "Trumpet" => UInt8(57),
    "Trombone" => UInt8(58),
    "Tuba" => UInt8(59),
    "MutedTrumpet" => UInt8(60),
    "FrenchHorn" => UInt8(61),
    "BrassSection" => UInt8(62),
    "SynthBrass1" => UInt8(63),
    "SynthBrass2" => UInt8(64),
    "SopranoSax" => UInt8(65),
    "AltoSax" => UInt8(66),
    "TenorSax" => UInt8(67),
    "BaritoneSax" => UInt8(68),
    "Oboe" => UInt8(69),
    "EnglishHorn" => UInt8(70),
    "Bassoon" => UInt8(71),
    "Clarinet" => UInt8(72),
    "Piccolo" => UInt8(73),
    "Flute" => UInt8(74),
    "Recorder" => UInt8(75),
    "PanFlute" => UInt8(76),
    "BlownBottle" => UInt8(77),
    "Shakuhachi" => UInt8(78),
    "Whistle" => UInt8(79),
    "Ocarina" => UInt8(80),
    "Lead1" => UInt8(81),
    "Lead2" => UInt8(82),
    "Lead3" => UInt8(83),
    "Lead4" => UInt8(84),
    "Lead5" => UInt8(85),
    "Lead6" => UInt8(86),
    "Lead7" => UInt8(87),
    "Lead8" => UInt8(88),
    "Pad1" => UInt8(89),
    "Pad2" => UInt8(90),
    "Pad3" => UInt8(91),
    "Pad4" => UInt8(92),
    "Pad5" => UInt8(93),
    "Pad6" => UInt8(94),
    "Pad7" => UInt8(95),
    "Pad8" => UInt8(96),
    "FX1" => UInt8(97),
    "FX2" => UInt8(98),
    "FX3" => UInt8(99),
    "FX4" => UInt8(100),
    "FX5" => UInt8(101),
    "FX6" => UInt8(102),
    "FX7" => UInt8(103),
    "FX8" => UInt8(104),
    "Sitar" => UInt8(105),
    "Banjo" => UInt8(106),
    "Shamisen" => UInt8(107),
    "Koto" => UInt8(108),
    "Kalimba" => UInt8(109),
    "Bagpipe" => UInt8(110),
    "Fiddle" => UInt8(111),
    "Shanai" => UInt8(112),
    "TinkleBell" => UInt8(113),
    "Agogo" => UInt8(114),
    "SteelDrums" => UInt8(115),
    "Woodblock" => UInt8(116),
    "TaikoDrum" => UInt8(117),
    "MelodicTom" => UInt8(118),
    "SynthDrum" => UInt8(119),
    "ReverseCymbal" => UInt8(120),
    "GuitarFretNoise" => UInt8(121),
    "BreathNoise" => UInt8(122),
    "Seashore" => UInt8(123),
    "BirdTweet" => UInt8(124),
    "TelephoneRing" => UInt8(125),
    "Helicopter" => UInt8(126),
    "Applause" => UInt8(127),
    "Gunshot" => UInt8(128)
)

export GM, NOTEOFF, NOTEON, POLYPHONICKEYPRESSURE, CONTROLCHANGE, PROGRAMCHANGE, CHANNELPRESSURE, PITCHWHEELCHANGE
