# master

## New `addevents!` function

* Now there is not only `addevent!` to add events to an existing track, but also
  `addevents!` which is significantly faster than calling `addevent!` many times,
  because it uses the new `addevent_hint` function to add the events. Use `addevents!` to add multiple events in one go.

* This also made `addnotes` significantly faster.

* Internally we implemented a new adding function
  `addevent_hint!` which is able to skip all `TrackEvent`s that surely lay before
  the new event to add.
