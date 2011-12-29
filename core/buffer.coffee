class Buffer
    constructor: (@data) ->
        @length = @data.length
    
    @allocate: (size) ->
        return new Buffer(new Uint8Array(size))
    
    copy: ->
        return new Buffer(new Uint8Array(@data))
    
    slice: (position, length) ->
        if position is 0 and length >= @length
            return new Buffer(@data)
        else
            return new Buffer(@data.subarray(position, position + length))