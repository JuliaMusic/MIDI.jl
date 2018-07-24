# Changelog of `MIDI`

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

# master
work in progress changes are contained in this section.

# v0.8.0
* Two new super-useful functions: `name_to_pitch` and `pitch_to_name`.

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
