for key, val of require './aurora_base'
    exports[key] = val

require './demuxers/caf'
require './demuxers/m4a'
require './demuxers/aiff'
require './demuxers/wave'
require './demuxers/au'

require './decoders/lpcm'
require './decoders/xlaw'