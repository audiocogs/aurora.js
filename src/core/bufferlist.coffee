class BufferList
    constructor: ->
        @first = null
        @last = null
        @numBuffers = 0
        @availableBytes = 0
        @availableBuffers = 0        
    
    copy: ->
        result = new BufferList

        result.first = @first
        result.last = @last
        result.numBuffers = @numBuffers
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
        @numBuffers++
        
    advance: ->
        if @first
            @availableBytes -= @first.length
            @availableBuffers--
            @first = @first.next
            return @first?
            
        return false
        
    rewind: ->
        if @first and not @first.prev
            return false
        
        @first = @first?.prev or @last
        if @first
            @availableBytes += @first.length
            @availableBuffers++
            
        return @first?
        
    reset: ->
        continue while @rewind()
        
module.exports = BufferList
