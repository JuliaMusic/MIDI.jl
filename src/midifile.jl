export MIDIFile, readMIDIfile, writeMIDIfile
export BPM, ms_per_tick

"""
    MIDIFile <: Any
Type representing a file of MIDI data.

## Fields
* `format::UInt16` : The format of the file. Can be 0, 1 or 2.
* `tpq::Int16` : The time division of the track, ticks-per-beat.
* `tracks::Array{MIDITrack, 1}` : The array of contained tracks.
"""
type MIDIFile
    format::UInt16 # The format of the file. Can be 0, 1 or 2
    tpq::Int16 # The time division of the track. Ticks per beat.
    tracks::Array{MIDITrack, 1} # An array of tracks
end

MIDIFile() = MIDIFile(0,96,MIDITrack[])

function readMIDIfileastype0(filename::AbstractString)
	MIDIfile = readMIDIfile(filename)
	if MIDIfile.format == 1
		type1totype0!(MIDIfile)
	end
	MIDIfile
end

function isMIDIFile(filename::AbstractString)::Bool
    endswith(lowercase(filename), ".mid")
end

"""
    readMIDIfile(filename::AbstractString)
Read a file into a `MIDIFile` data type.
"""
function readMIDIfile(filename::AbstractString)
    if length(filename) < 4 || isMIDIFile(filename)
	f *= ".mid"
    end
    f = open(filename)

    MIDIfile = MIDIFile()
    # Check that it's a valid MIDI file - first four bytes should spell MThd
    mthd = join(map(Char, read(f, UInt8, 4)))
    if mthd != MTHD
        error("Not a valid MIDI file. Expected first 4 bytes to spell 'MThd', got $(mthd)")
    end

    # Skip the next four bytes - this is the header size, and it's always equal to 6.
    skip(f, 4)

    # Read the format code. 0 = single track, 1 = multiple tracks, 2 = multiple songs
    # Remember - MIDI files store data in big-endian format, which is why ntoh is used
    MIDIfile.format = ntoh(read(f, UInt16))

    # Get the number of tracks and time division
    numberoftracks = ntoh(read(f, UInt16))
    MIDIfile.tpq = ntoh(read(f, Int16))
    MIDIfile.tracks = [readtrack(f) for x in 1:numberoftracks]
    close(f)

    MIDIfile
end

"""
    writeMIDIfile(filename::AbstractString, data::MIDIFile)
Write a `MIDIFile` as a ".mid" file to the given filename.
"""
function writeMIDIfile(filename::AbstractString, data::MIDIFile)
    if length(filename) < 4 || isMIDIFile(filename)
      filename *= ".mid"
    end

    f = open(filename, "w")

    write(f, convert(Array{UInt8, 1}, MTHD)) # File identifier
    write(f, hton(convert(UInt32, 6))) # Header length
    write(f, hton(data.format))
    write(f, hton(convert(UInt16, length(data.tracks))))
    write(f, hton(data.tpq))

    map(track->writetrack(f, track), data.tracks)

    close(f)
end


"""
    BPM(midi)
Return the BPM where the given `MIDIFile` was exported at.
"""
function BPM(t::MIDI.MIDIFile)
  # META-event list:
  tlist = [x for x in t.tracks[1].events]
  tttttt = Vector{UInt32}
  # Find the one that corresponds to Set-Time:
  # The event tttttt corresponds to the command
  # FF 51 03 tttttt Set Tempo (in microseconds per MIDI quarter-note)
  # See here (page 8):
  # http://www.cs.cmu.edu/~music/cmsip/readings/Standard-MIDI-file-format-updated.pdf
  for i in 1:length(tlist)
    if typeof(tlist[i]) == MIDI.MetaEvent
      y = tlist[i]
      if y.metatype == 0x51
        tttttt = deepcopy(y.data)
        break
      end
    end
  end
  # Ensure that tttttt is with correct form (first entry should be 0x00)
  if tttttt[1] != 0x00
      unshift!(tttttt, 0x00)
  else
      # Handle correctly "incorrect" cases where 0x00 has entered more than once
      tttttt = tttttt[findin(tttttt, 0x00)[end]:end]
  end

  # Get the microsecond number from tttttt
  u = ntoh(reinterpret(UInt32, tttttt)[1])
  μs = Int64(u)
  # BPM:
  bpm = round(Int, 60000000/μs)
end

"""
    ms_per_tick(midi, bpm::Integer = BPM(midi)) -> ms
Given a `MIDIFile`, return how many miliseconds is one tick, based
on the `bpm`. By default the `bpm` is the BPM the midi file was exported at.
"""
function ms_per_tick(midi::MIDI.MIDIFile, bpm::Int = BPM(midi))
  tpq = midi.tpq
  tick_ms = (1000*60)/(bpm*tpq)
end

getnotes(midi::MIDIFile, trackno = 2) = getnotes(midi.tracks[trackno], midi.tpq)
