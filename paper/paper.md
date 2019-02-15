---
title: 'MIDI.jl: Simple and intuitive handling of MIDI data.'
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
**MIDI.jl** is a Julia [@Julia] package for reading, writing and analyzing [MIDI](https://www.midi.org/specifications) data. In this paper we are briefly overviewing versions `1.1.0` or later for **MIDI.jl**.

MIDI (Music Instrument Digital Interface) is a data format created to transmit music data across devices and computers. The [actual MIDI interface](https://www.midi.org/specifications) is very low level, directly translating all music information to and from byte chunks.
**MIDI.jl** exposes all this low level interface, but it also builds a useable high-level interface on top of that. This makes reading MIDI data easier than ever before.

# Documentation
All functionality of **MIDI.jl** is very well documented and hosted online. The documentation link can be found [here](https://juliamusic.github.io/JuliaMusic_documentation.jl/latest/).
Besides documentation of functions there are plenty of useful real world examples.
Because of the rich documentation, in this paper we will only showcase specific strengths and design decisions that can make working with music data very easy.

# Intuitive and Simple Interface
The biggest strength of **MIDI.jl** is the ability to transform the raw MIDI data in a format that is human-readable, intuitive and simple to use and manipulate. In addition the high level interface does not require knowledge of which exact MIDI code corresponds to which exact MIDI command.

What makes this possible is the data structures we create in order to provide easier handling of MIDI files. The most important data structure is the `Note`/`Notes`. A music note can be (in its most basic level) deconstructed into just four numbers: the temporal position that the note is played, the duration, the pitch and the intensity (strength with which the note is played, also called velocity). A `Note` is a data structure that has these four "quantities" as its "fields". All of these are accessible immediately with e.g. `Note.position` and their values can be mutated in place.

These aspects can be deduced from the raw MIDI format with a lot of analyzing of bytes. However, in **MIDI.jl** we provide a simple function:
```julia
getnotes(midi, args...)
```
which obtains all note-specific information and stores it as a vector of notes, which we call `Notes`. This is very convenient, as to "identify" a note in the MIDI format, one needs to first identify two different streams of bytes; one denotes the start and the other the end of the note. This quickly becomes tedious, but `getnotes` does not expose all these details to the user.

# Extensions
This easy to use high level interface allows **MIDI.jl** to be extendable. In e.g. another software package **MusicManipulations.jl** we provide general functions for manipulating (and further analyzing) music data.

For example, the function `quantize` from the package **MusicManipulations.jl** allows the user to quantize any `Notes` instance to any grid. This functionality is offered by Digital Audio Workstations, like the software Cubase, but we offer ways to do it programmatically instead. Many other helpful functions are contained in **MusicManipulations.jl**, and for further reading we point to the official documentation of the [JuliaMusic](https://juliamusic.github.io/JuliaMusic_documentation.jl/latest/) GitHub organization, which hosts both **MIDI.jl** and **MusicManipulations.jl**, as well as other useful packages.


# Scientific Application
Microtiming deviations are defined as temporal deviations below the phrase level, typically in the millisecond range. These have been studied extensively in the literature and their importance and influence are debated strongly, see  [@Madison2011, @Butterfield2010, @Fruehauf2013, @Davies2013, @Senn2016, @Hofmann2017] and references therein.

Qualitative studies of these microtiming deviations have been done extensively by Geisel and coworkers [@Hennig2011, @Hennig2014, @Raesaenen2015, @Sogorski2018]. A crucial finding is that the sequence of such deviations is not random but power-law correlated. In addition there is very strong evidence that their distribution is normal (Gaussian).

In the following we will compute the distribution of the microtiming deviations of a piano track (played by a professional pianist) and show that indeed it approximates a normal distribution.

We first load the notes of the piano track:
```julia
using MusicManipulations # Re-exports MIDI
midi = readMIDIFile(testmidi()) # test midi file

# Track number 4 is the piano track
piano = midi.tracks[4]
notes = getnotes(piano, midi.tpq)
```
```
533 Notes with tpq=960
 Note F4  | vel = 69  | pos = 7427, dur = 181
 Note A♯4 | vel = 85  | pos = 7760, dur = 450
 Note D5  | vel = 91  | pos = 8319, dur = 356
 Note D4  | vel = 88  | pos = 8323, dur = 314
 Note G♯3 | vel = 88  | pos = 8327, dur = 358
 Note A♯4 | vel = 76  | pos = 8694, dur = 575
 Note G4  | vel = 66  | pos = 9281, dur = 273
 Note A♯4 | vel = 94  | pos = 9594, dur = 666
 Note F♯3 | vel = 98  | pos = 10189, dur = 307
 Note C4  | vel = 87  | pos = 10206, dur = 285
  ⋮
```
We then compute their microtiming deviations. For the purpose of this article, we define the microtiming deviations of a note as the distance of the position of a note from its position when quantized on a 8th-note triplet grid (the pianist was playing triplets in the above midi file).

We now compute those microtiming deviations, using the function `quantize` from **MusicManipulations.jl**
```julia
grid = 0:(1//3):1 # grid to quantize on, see documentation
qnotes = quantize(notes, grid)
mtds = positions(notes) .- positions(qnotes)
mtds_ms = mtds .* ms_per_tick(midi)
```
```
533-element Array{Float64,1}:
  32.21150624999999
  38.461499999999994
   ⋮
  12.499987499999998
  13.461524999999998
```
A plot of the histogram of these is presented in Figure 1. Even if produced with an extremely small pool of data, the plot follows the existing evidence that the distribution of the microtiming deviations follows a normal distribution.

![Histogram of the microtiming deviations of a simple piano recording.](mtd_hist.png)

# Necessity of MIDI.jl

As of 8th January 2019, **MIDI.jl** is the only package for the Julia programming language that offers this functionality.

# Conclusions
In conclusion, **MIDI.jl** is a useful package with very intuitive usage, as we have demonstrated by our simple application. In addition it has plenty more use for scientific applications. In *G. Datseris et al. "Does it Swing? Microtiming Deviations and Swing Feeling in Jazz"* [@Datseris2019], the authors have used **MIDI.jl** and its extensions to not only read but also manipulate microtiming deviations of human recordings in order to inquire about the impact of microtiming deviations in the listening experience.

# References
