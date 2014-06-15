Filter = require '../filter'

class BalanceFilter extends Filter
    process: (buffer) ->
        return if @value is 0
        pan = Math.max(-50, Math.min(50, @value))
        
        for i in [0...buffer.length] by 2
            buffer[i] *= Math.min(1, (50 - pan) / 50)
            buffer[i + 1] *= Math.min(1, (50 + pan) / 50)
            
        return
        
module.exports = BalanceFilter
