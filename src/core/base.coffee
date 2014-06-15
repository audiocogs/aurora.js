#
# The Base class defines an extend method so that
# CoffeeScript classes can be extended easily by 
# plain JavaScript. Based on http://ejohn.org/blog/simple-javascript-inheritance/.
#

class Base
    fnTest = /\b_super\b/
    
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
            # test whether the method actually uses _super() and wrap it if so
            if typeof fn is 'function' and fnTest.test(fn)
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
        
module.exports = Base
