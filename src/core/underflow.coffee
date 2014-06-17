# define an error class to be thrown if an underflow occurs
class UnderflowError extends Error
    constructor: ->
        super
        @name = 'UnderflowError'
        @stack = new Error().stack

module.exports = UnderflowError
