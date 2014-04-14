noOp = ->

###*
 * AV.BufferedPipe is an asynchronous, buffered pipe. It implements flow control
 * using a callback function named more().
###
class AV.BufferedPipe extends AV.EventEmitter

    ###*
     * @constructor
     * @param  {function=} more - Fires when the pipe needs more data
    ###
    constructor: (@more = noOp) ->
        @readyMark = 64
        @ended = false
        @buffers = []
        
        @more() unless @isReady()
    
    ###*
     * Writes one chunk of data to the end of the buffer.
     * Calls more() to request data if necessary.
     * @param  {*} buffer
     * @return {!bool} isReady - True if enough data has been buffered
    ###
    write: (buffer) =>
        wasReady = @isReady()

        return wasReady unless buffer

        @buffers.push buffer
        isReady = @isReady()

        if isReady
            @emit 'ready' if not wasReady
        else
            @more()

        return isReady
    
    ###*
     * Returns the next chunk of data. Calls more() to request
     * data if necessary.
     * @return {*} data
    ###
    read: ->
        buffer = @buffers.shift()

        @more() unless @isReady()

        return buffer
    
    ###*
     * Returns true if enough data has been buffered.
     * @return {!boolean}
    ###
    isReady: ->
        @buffers.length >= @readyMark or @ended

    ###*
     * Clears out the current buffer and requests new data.
    ###
    reset: ->
        @buffers.length = 0
        @more() unless @isReady()
        return
