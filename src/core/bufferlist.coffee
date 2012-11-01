class AV.BufferList
    constructor: ->
        @first = null
        @last = null
        @availableBytes = 0
        @availableBuffers = 0        
    
    copy: ->
        result = new AV.BufferList

        result.first = @first
        result.last = @last
        result.availableBytes = @availableBytes
        result.availableBuffers = @availableBuffers
        
        return result
        
    append: (buffer) ->
        buffer.prev = @last
        @last?.next = buffer
        @last = buffer
        @first ?= buffer
        
        @availableBytes += buffer.length
        @availableBuffers++
        
    advance: ->
        if @first
            @availableBytes -= @first.length
            @availableBuffers--
            @first = @first.next
        
    rewind: ->
        if @first?.prev
            @first = @first.prev
            @availableBytes += @first.length
            @availableBuffers++