# Changelog of `MIDI`

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

# master

# v1.3.0
Improved the printing of `TrackEvent`s. They now state the amount of elements in them, as well as listing how many or of each type. E.g.:
```
julia> midi.tracks
5-element Array{MIDITrack,1}:
 3-event MIDITrack: 0 MIDI, 3 Meta, 0 Sysex
 5729-event MIDITrack: 5728 MIDI, 1 Meta, 0 Sysex
 8467-event MIDITrack: 8466 MIDI, 1 Meta, 0 Sysex
 21487-event MIDITrack: 21486 MIDI, 1 Meta, 0 Sysex
 9773-event MIDITrack: 9772 MIDI, 1 Meta, 0 Sysex
```

# v1.2.0
Removed deprecations.

# v1.1.0
See https://github.com/JuliaMusic/MIDI.jl/pull/112

We have changed `name_to_pitch` so that `"C4"` corresponds to midi pitch 60.

# v1.0.0
No change, just stable release.

# v0.8.0
* Two new super-useful functions: `name_to_pitch` and `pitch_to_name`.
* Function `testmidi()` that returns the path to `doxy.mid`.

# v0.7.0

## Breaking
* `BPM(midi)` does not return the value rounded to an integer anymore. It returns
  the computed division instead.

* `ms_per_tick` has now two methods: either one that accepts `tpq, bpm` or
  one that accepts a `midi` file.

## Improvements
* `BPM` is now faster as it iterates over events.
* Pretty printing for `MIDIFile`.
* Added functions `textevent` and `findtextevents` that create and find
  text related meta events (lyrics, text, markers).
* Possible to write a midi file directly from notes.


# v0.6.2

* Minor documentation Improvements.
* Improvement on `show` of `Notes`, especially the vectorized form.

# v0.6.0

We now drop support for Julia 0.6 and only support ≥ 0.7.

## New `addevents!` function

* Now there is not only `addevent!` to add events to an existing track, but also
  `addevents!` which is significantly faster than calling `addevent!` many times,
  because it uses the new `addevent_hint` function to add the events. Use `addevents!` to add multiple events in one go.

* This also made `addnotes` significantly faster.

* Internally we implemented a new adding function
  `addevent_hint!` which is able to skip all `TrackEvent`s that surely lay before
  the new event to add.
