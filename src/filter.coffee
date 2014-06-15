class Filter
    constructor: (context, key) ->
        # default constructor takes a single value
        # override to take more parameters
        if context and key
            Object.defineProperty this, 'value', 
                get: -> context[key]
        
    process: (buffer) ->
        # override this method
        return
        
module.exports = Filter
