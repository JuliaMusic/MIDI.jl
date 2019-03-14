# MIDI.jl

| **Documentation**   | **Travis**     | **AppVeyor** | **Citation** |
|:--------:|:--------:|:---------------:|:------:|
|[![](https://img.shields.io/badge/docs-online-blue.svg)](https://juliamusic.github.io/JuliaMusic_documentation.jl/latest/)| [![Build Status](https://travis-ci.org/JuliaMusic/MIDI.jl.svg?branch=master)](https://travis-ci.org/JuliaMusic/MIDI.jl) | [![Build status](https://ci.appveyor.com/api/projects/status/4mpn9vgfa7wh0jtq?svg=true)](https://ci.appveyor.com/project/JuliaDynamics/midi-jl-h79xk) | [![status](http://joss.theoj.org/papers/e0cfc67982f857ed96d906ff2266aa15/status.svg)](http://joss.theoj.org/papers/e0cfc67982f857ed96d906ff2266aa15)

---

MIDI.jl is a complete Julia package for reading and writing MIDI data. Besides fundamentally basic types, like `MIDITrack` or `MetaEvent`, we have a robust type that describes a music note.

## Installation
To install the latest stable release, use `]add MIDI`. To install the development version, use `]dev MIDI`.

## Documentation
For usage examples, documentation, contact info and everything else relevant with how `MIDI` works please visit the official documentation page: https://juliamusic.github.io/JuliaMusic_documentation.jl/latest/.

## Other
For the release history see the [CHANGELOG](CHANGELOG.md) file. For the contributor guide see [CONTRIBUTING](CONTRIBUTING.md). For the code of conduit see [COC](COC.md).

## Citing

If you used **MIDI.jl** or **MusicManipulations.jl** in research that resulted in publication, then please cite our paper using the following BibTeX entry:
```latex
@article{Datseris2019,
  doi = {10.21105/joss.01166},
  url = {https://doi.org/10.21105/joss.01166},
  year  = {2019},
  month = {mar},
  publisher = {The Open Journal},
  volume = {4},
  number = {35},
  pages = {1166},
  author = {George Datseris and Joel Hobson},
  title = {{MIDI}.jl: Simple and intuitive handling of MIDI data.},
  journal = {The Journal of Open Source Software}
}
```
