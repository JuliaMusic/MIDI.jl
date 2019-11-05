export MIDIFile, readMIDIFile, writeMIDIFile
export BPM, ms_per_tick

"""
    MIDIFile <: Any
Type representing a file of MIDI data.

## Fields
* `format::UInt16` : The format of the file. Can be 0, 1 or 2.
* `tpq::Int16` : The time division of the track, ticks-per-quarter-note.
* `tracks::Array{MIDITrack, 1}` : The array of contained tracks.
"""
mutable struct MIDIFile
    format::UInt16 # Can be 0, 1 or 2
    tpq::Int16 # The time division of the track. Ticks per quarter note
    tracks::Vector{MIDITrack}
end
# Pretty print
function Base.show(io::IO, midi::MIDIFile) where {N}
	tnames = tracknames(midi)
	s = "MIDIFile (format=$(Int(midi.format)), tpq=$(midi.tpq)) "
	if any(!isequal(NOTRACKNAME), tnames) # we have tracknames
		s *= "with tracks:\n"
		for t in tnames
			s *= " "*t*"\n"
		end
	else # some track doesn't have a name
		s *= "with $(length(midi.tracks)) tracks"
	end
	print(io, s)
end


MIDIFile() = MIDIFile(0,960,MIDITrack[])

function readMIDIFileastype0(filename::AbstractString)
	MIDIFile = readMIDIFile(filename)
	if MIDIFile.format == 1
		type1totype0!(MIDIFile)
	end
	MIDIFile
end

"""
    readMIDIFile(filename::AbstractString)
Read a file into a `MIDIFile` data type.
"""
function readMIDIFile(filename::AbstractString)
    if length(filename) < 4 || filename[end-3:end] != ".mid"
		filename *= ".mid"
    end
    f = open(filename)

    midifile = MIDIFile()
    # Check that it's a valid MIDI file - first four bytes should spell MThd
    mthd = join(map(Char, read!(f, Array{UInt8}(undef, 4))))
    if mthd != MTHD
        error("Not a valid MIDI file. Expected first 4 bytes to spell 'MThd', got $(mthd)")
    end

    # Skip the next four bytes - this is the header size, and it's always equal to 6.
    skip(f, 4)

    # Read the format code. 0 = single track, 1 = multiple tracks, 2 = multiple songs
    # Remember - MIDI files store data in big-endian format, which is why ntoh is used
    midifile.format = ntoh(read(f, UInt16))

    # Get the number of tracks and time division
    numberoftracks = ntoh(read(f, UInt16))
    midifile.tpq = ntoh(read(f, Int16))
    midifile.tracks = [readtrack(f) for x in 1:numberoftracks]
    close(f)

    midifile
end

readMIDIFile() = readMIDIFile(testmidi())

"""
    writeMIDIFile(filename::AbstractString, data::MIDIFile)
Write a `MIDIFile` as a ".mid" file to the given filename.

    writeMIDIFile(filename::AbstractString, notes::Notes)
Create a `MIDIFile` directly from `notes`, using format 1.
"""
function writeMIDIFile(filename::AbstractString, data::MIDIFile)
    if length(filename) < 4 || lowercase(filename[end-3:end]) != ".mid"
      filename *= ".mid"
    end

    f = open(filename, "w")

    write(f, MTHD) # File identifier
    write(f, hton(convert(UInt32, 6))) # Header length
    write(f, hton(data.format))
    write(f, hton(convert(UInt16, length(data.tracks))))
    write(f, hton(data.tpq))

    map(track->writetrack(f, track), data.tracks)

    close(f)
    return data
end

function writeMIDIFile(filename::AbstractString, notes::Notes)
    if length(filename) < 4 || lowercase(filename[end-3:end]) != ".mid"
      filename *= ".mid"
    end

    track = MIDITrack()
    addnotes!(track, notes)
    midi = MIDIFile(1, notes.tpq, [track])
    writeMIDIFile(filename, midi)
    return midi
end


"""
    BPM(midi)
Return the BPM where the given `MIDIFile` was exported at.
"""
function BPM(t::MIDI.MIDIFile)
    # META-event list:
    tttttt = Vector{UInt32}()
    # Find the one that corresponds to Set-Time:
    # The event tttttt corresponds to the command
    # FF 51 03 tttttt Set Tempo (in microseconds per MIDI quarter-note)
    # See here (page 8):
    # http://www.cs.cmu.edu/~music/cmsip/readings/Standard-MIDI-file-format-updated.pdf
    for event in t.tracks[1].events
        if typeof(event) == MetaEvent
            if event.metatype == 0x51
                tttttt = deepcopy(event.data)
                break
            end
        end
    end
    # Ensure that tttttt is with correct form (first entry should be 0x00)
    if tttttt[1] != 0x00
        pushfirst!(tttttt, 0x00)
    else
        # Handle correctly "incorrect" cases where 0x00 has entered more than once
        tttttt = tttttt[findin(tttttt, 0x00)[end]:end]
    end

    # Get the microsecond number from tttttt
    u = ntoh(reinterpret(UInt32, tttttt)[1])
    μs = Int64(u)
    # BPM:
    bpm = 60000000/μs
end



"""
    ms_per_tick(tpq, bpm)
    ms_per_tick(midi::MIDIFile)
Return how many miliseconds is one tick, based
on the beats per minute `bpm` and ticks per quarter note `tpq`.
"""
ms_per_tick(midi::MIDI.MIDIFile, bpm = BPM(midi)) = ms_per_tick(midi.tpq, bpm)
ms_per_tick(tpq, bpm) = (1000*60)/(bpm*tpq)

getnotes(midi::MIDIFile, trackno = 2) = getnotes(midi.tracks[trackno], midi.tpq)
