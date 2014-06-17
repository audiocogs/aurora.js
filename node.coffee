for key, val of require './src/aurora'
    exports[key] = val
    
require './src/devices/node-speaker'
