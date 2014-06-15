for key, val of require './src/aurora'
  exports[key] = val
    
require './src/sources/browser/http'
require './src/sources/browser/file'
require './src/devices/webaudio'
require './src/devices/mozilla'
