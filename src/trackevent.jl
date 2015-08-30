# Abstract type for Midi events
abstract TrackEvent

#=
All track events begin with a variable length time value (see readvariablelength()).
Midi events start with a midi channel message defined in constants.jl. They're followed by 1 or 2 bytes, depending on the
channel message (see EVENTTYPETOLENGTH). If no valid channel message is identified, the previous seen channel message is used.
Meta events and sysex events both begin with a specific byte (see constants.jl)
=#
