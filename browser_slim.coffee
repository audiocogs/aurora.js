for key, val of require './src/aurora_base'
  exports[key] = val
  
require './src/devices/webaudio'
require './src/devices/mozilla'
