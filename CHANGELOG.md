# MASTER

### Made `addnotes` significantly faster.

The old version was calling ´addevent!´ for each `NOTEON` or `NOTEOFF` event.
`addevent!` always starts to search the MIDITrack for the correct insertion position
at the beginning of the track. Now we implemented a new adding function
`addevent_hint` which is able to skip all `TrackEvent`s that surely lay before
the new event to add. For $N$ notes in successive order this reduces the complexity
of the algorithm from O(N²) to O(N) which leads to significant speedup.

### New `addevents!` function

Now there is not only `addevent!` to add events to an existing track, but also
`addevents!` which is significantly faster than calling `addevent!` many times,
because it uses the new `addevent_hint` function to add the events.

Please replace code like
``` julia
for i = 1:X
    addevent!(track, positions[i], events[i])
end
```
by
``` julia
addevents!(track, positions, events)
```
to increase performance.
