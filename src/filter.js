void function (global) {
	'use strict'

	var filter = Aurora.extend(Aurora.object, 'Aurora::Filter', {}, {
		value: { get: function () { return this.$.context[this.$.key] } }
	})

	filter.constructor = function (context, key) {
		Aurora.object.constructor.apply(this)
		
		this.$.context = context, this.$.key = key
	}

	filter.process = function (buffer) {
		return
	}

	Aurora.filter = filter
	Aurora.Filter = filter.constructor

	Aurora.Filter.prototype = filter
}(this)
