---
title: 'MIDI.jl: Intuitive handling of MIDI data made for musicians.'
tags:
  - music
  - MIDI
  - midi
  - note
  - notes
authors:
 - name: George Datseris
   orcid: 0000-0002-6427-2385
   affiliation: "1, 2"
 - name: Joel Hobson
   affiliation: 3
affiliations:
 - name: Max Planck Institute for Dynamics and Self-Organization
   index: 1
 - name: Department of Physics, Georg-August-Universität Göttingen
   index: 2
 - name: Roadmunk Inc.
   index: 3
date: 21 December 2018
bibliography: paper.bib
---


# Introduction
**MIDI.jl** is a Julia [@Julia] package for reading, writing and analyzing [MIDI](https://www.midi.org/specifications) data. MIDI (Music Instrument Digital Interface) is a data format created to transmit music data across devices and computers. The [actual MIDI interface](https://www.midi.org/specifications) is very low level, directly translating all music information to and from byte chunks.

**MIDI.jl** takes a different approach: besides exposing all this low level interface, it also builds a useable high-level interface on top of that. This makes reading MIDI data easier than ever before.

## Documentation
All functionality of **MIDI.jl** is very well documented and hosted online. The documentation link can be found [here](https://juliamusic.github.io/JuliaMusic_documentation.jl/latest/).
Besides documentation of functions there are plenty of useful real world examples.
Because of the rich documentation, in this paper we will only showcase specific strengths and design decisions that can make working with music data very easy.

# Made for Musicians
The low level representation of the MIDI format is available from our **MIDI.jl** package. However the biggest strength of **MIDI.jl** is the ability to transform the raw MIDI data in a format that is readable and intuitive for people that are just musicians (with knowledge of just a bit of Julia) and not computer scientists or engineers with experience working with bits and bytes.

What makes this possible is the data structures we create in order to provide easier handling of MIDI files. The most important data structure is the `Note` (and the plural version `Notes`). A music note can be (in its most basic level) deconstructed into just four numbers: the temporal position that the note is played, the duration, the pitch and the intensity (strength with which the note is played, also called velocity). A `Note` is a data structure that has exactly (and only) these four "quantities" as its "fields". All of these are accessible immediately with e.g. `Note.position` and their values can be mutated in place.

These aspects can be deduced from the raw MIDI format with a lot of analyzing of bytes. However, in **MIDI.jl** we provide a simple function:
```julia
getnotes(midi, args...)
```
which obtains all note-specific information and stores it as a vector of notes, which we call `Notes`. This is very convenient, as to "identify" a note in the MIDI format, one needs to first identify two different streams of bytes; one denotes the start and the other the end of the note. This quickly becomes tedious, but `getnotes` does not expose all these details to the user.

# Example
For example, this piece of code
```julia
using MIDI
midi = readMIDIFile(testmidi()) # test midi file

# Track number 3 is a quantized bass MIDI track
bass = midi.tracks[3]
notes = getnotes(bass, midi.tpq)
println("Notes of track $(trackname(bass)):")
@show notes
```
produces:
```
Notes of track Bass:
177 Notes with tpq=960
 Note A♯3 | vel = 95  | pos = 7680, dur = 690
 Note A♯3 | vel = 71  | pos = 9280, dur = 308
 Note G♯3 | vel = 52  | pos = 9600, dur = 668
 Note G♯3 | vel = 58  | pos = 11200, dur = 338
 Note G3  | vel = 71  | pos = 11520, dur = 701
 Note G♯3 | vel = 83  | pos = 13120, dur = 281
 Note G3  | vel = 73  | pos = 13440, dur = 855
 Note D3  | vel = 80  | pos = 14400, dur = 848
 Note C3  | vel = 68  | pos = 15360, dur = 986
 Note F♯2 | vel = 72  | pos = 16320, dur = 866
  ⋮
```
Importantly, the opposite (i.e. writing a sequence of notes) is just as easy:
```julia
using MIDI
C = Note(60, 96, 0, 192)
E = Note(64, 96, 48, 144)
G = Note(67, 96, 96, 96)

file = MIDIFile()
track = MIDITrack()
notes = Notes() # tpq automatically = 960

push!(notes, C)
push!(notes, E)
push!(notes, G)

inc = 192
# Notes one octave higher
C = Note(60 + 12, 96, C.position+inc, 192)
E = Note(64 + 12, 96, E.position+inc, 144)
G = Note(67 + 12, 96, G.position+inc, 96)

addnotes!(track, notes)
addtrackname!(track, "simple track")
push!(file.tracks, track)
writeMIDIFile("test.mid", file);
```

In the above, besides the intuitive `Notes` format, we also highlighted the functions `trackname` and `addtrackname!` which decode a normal string into the necessary bytes and commands expected by the MIDI format.

Such high-level interfaces is what make the **MIDI.jl** package extremely useful for musicians. Besides, **MIDI.jl** is (currently) the only MIDI library for the Julia language.

# Extensions
This easy to use high level interface allows **MIDI.jl** to be extendable. In e.g. another software package **MusicManipulations.jl** we provide general functions for manipulating (and further analyzing) music data.

For example, the function `quantize` from the package **MusicManipulations.jl** allows the user to quantize any `Notes` instance to any grid. This functionality is offered by Digital Audio Workstations, like the software Cubase, but we offer ways to do it programmatically instead. Many other helpful functions are contained in **MusicManipulations.jl**, and for further reading we point to the official documentation of the [JuliaMusic](https://juliamusic.github.io/JuliaMusic_documentation.jl/latest/) GitHub organization, which hosts both **MIDI.jl** and **MusicManipulations.jl**, as well as other useful packages.
