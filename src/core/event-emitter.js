void function (global) {
	'use strict'

	var eventEmitter = Aurora.extend(Aurora.object, 'Aurora::EventEmitter', {
		events: { value: {} }
	})

	eventEmitter.constructor = function () {
		Aurora.object.constructor.apply(this)
	}

	eventEmitter.on = function (event, fn) {
		var callbacks = this.$.events[event] || []
		callbacks.push(fn)
		this.$.events[event] = callbacks
	}

	eventEmitter.off = function (event, fn) {
		var array = this.$.events[event]

		if (array) {
			var index = array.indexOf(fn)
			if (index != -1) {
				array.splice(index, 1)
			}
		}
	}

	eventEmitter.once = function (event, fn) {
		var cb = function () {
			this.off(event, cb)
			fn.apply(this, arguments)
		}
		this.on(event, cb)
	}

	eventEmitter.emit = function (event) {
		var array = this.$.events[event], args = Array.prototype.slice.call(arguments, 1)
		if (array) {
			for (var i = 0; i < array.length; i++) {
				array[i].apply(this, args)
			}
		}
	}

	Aurora.eventEmitter = eventEmitter
	Aurora.EventEmitter = eventEmitter.constructor

	Aurora.EventEmitter.prototype = eventEmitter
}(this)
