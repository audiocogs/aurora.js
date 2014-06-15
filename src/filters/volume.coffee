Filter = require '../filter'

class VolumeFilter extends Filter
    process: (buffer) ->
        return if @value >= 100
        vol = Math.max(0, Math.min(100, @value)) / 100
        
        for i in [0...buffer.length] by 1
            buffer[i] *= vol
            
        return
        
module.exports = VolumeFilter
