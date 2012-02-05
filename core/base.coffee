#
# The Base class defines an extend method so that
# CoffeeScript classes can be extended easily by 
# plain JavaScript.
#

class Base
    @extend: (prop) ->
        class Class extends this
            
        if typeof prop is 'function'
            keys = Object.keys Class.prototype
            prop.call(Class, Class)
            
            prop = {}
            for key, fn of Class.prototype when key not in keys
                prop[key] = fn
        
        _super = Class.__super__
        
        for key, fn of prop
            if typeof fn is 'function'
                do (key, fn) ->
                    Class::[key] = ->
                        tmp = this._super
                        this._super = _super[key]
                        
                        ret = fn.apply(this, arguments)
                        this._super = tmp
                        
                        return ret
                        
            else
                Class::[key] = fn
                
        return Class