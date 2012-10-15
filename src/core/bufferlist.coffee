class AV.BufferList
    constructor: ->
        @buffers = []
        @availableBytes = 0
        @availableBuffers = 0        
        @first = null
    
    copy: ->
        result = new AV.BufferList

        result.buffers = @buffers.slice(0)
        result.first = result.buffers[0]
        result.availableBytes = @availableBytes
        result.availableBuffers = @availableBuffers
        
        return result
    
    shift: ->
        result = @buffers.shift()
        
        @availableBytes -= result.length
        @availableBuffers -= 1
        
        @first = @buffers[0]
        return result
    
    push: (buffer) ->
        @buffers.push(buffer)
        
        @availableBytes += buffer.length
        @availableBuffers += 1
        
        @first = buffer unless @first
        return this
    
    unshift: (buffer) ->
        @buffers.unshift(buffer)
        
        @availableBytes += buffer.length
        @availableBuffers += 1
        
        @first = buffer
        return this