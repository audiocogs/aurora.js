class EventEmitter extends Base
    on: (event, fn) ->
        @events ?= {}
        @events[event] ?= []
        @events[event].push(fn)
        
    off: (event, fn) ->
        return unless @events?[event]
        index = @events[event].indexOf(fn)
        @events[event].splice(index, 1) if ~index
        
    once: (event, fn) ->
        @on event, cb = =>
            @off event, cb
            fn arguments...
        
    emit: (event, args...) ->
        return unless @events?[event]
        
        for fn in @events[event]
            fn args...
            
        return