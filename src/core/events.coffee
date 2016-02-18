Base = require './base'

class EventEmitter extends Base
    on: (event, fn) ->
        @events ?= {}
        @events[event] ?= []
        @events[event].push(fn)
        
    off: (event, fn) ->
        return unless @events?
        if @events?[event]
            if fn?
                index = @events[event].indexOf(fn)
                @events[event].splice(index, 1) if ~index
            else
                @events[event]
        else unless event?
            events = {}
        
    once: (event, fn) ->
        @on event, cb = ->
            @off event, cb
            fn.apply(this, arguments)
        
    emit: (event, args...) ->
        return unless @events?[event]
        
        # shallow clone with .slice() so that removing a handler
        # while event is firing (as in once) doesn't cause errors
        for fn in @events[event].slice()
            fn.apply(this, args)
            
        return
        
module.exports = EventEmitter
