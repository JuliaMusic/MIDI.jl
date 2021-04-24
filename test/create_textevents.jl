let

tpq = 960
p = 0x4f

n = Notes([
Note(p, 100, 0, tpq),
Note(p, 100, tpq, tpq),
Note(p, 100, 2tpq, tpq),
Note(p, 100, 3tpq, tpq),
Note(p, 100, 4tpq, tpq),
Note(p, 100, 5tpq, tpq),
Note(p, 100, 6tpq, tpq),
Note(p, 100, 7tpq, tpq),
Note(p, 100, 8tpq, tpq)
], tpq)

track = MIDITrack()

addnotes!(track, n)

lyrics = [textevent(:lyric, i == 3 ? "lnt" : "l") for i in 1:3]
addevents!(track, [0, tpq, 2tpq], lyrics)

texts = [textevent(:text, i == 3 ? "tnl" : "t") for i in 1:3]
addevents!(track, [0, tpq, 2tpq], texts)

markers = [textevent(:marker, X) for X in ["A", "B"]]
addevents!(track, [0, 4tpq], markers)

midi = MIDIFile(0, tpq, [track])
cd(@__DIR__)
save("texts.mid", midi)

midi = load("texts.mid")
t = midi.tracks[1]

@test findtextevents(:marker, t)[1] == ["A", "B"]
@test findtextevents(:text, t)[1]  == ["t", "t", "tnl"]
@test findtextevents(:lyric, t)[1] == ["l", "l", "lnt"]

rm("texts.mid")

end
