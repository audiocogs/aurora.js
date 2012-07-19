void function (global) {
	'use strict'

	Aurora.object = Object.create({}, {
		$: { value: {}, configurable: true },
		typename: { value: 'Aurora::Object', enumerable: true, configurable: true },
		prototype: {
			get: function () {
				return Object.getPrototypeOf(this)
			},
			enumerable: true
		}
	})

	Aurora.object.constructor = function () {
		Object.defineProperty(this, '$', { value: this.prototype.$.__cs_clone(2) })
	}

	Aurora.object.clone = function (depth) {
		var result = Object.create(Object.getPrototypeOf(this))

		var keys = Object.getOwnPropertyNames(this), remaining = depth ? depth - 1 : 0

		if (remaining > 0) {
			for (var i = 0; i < keys.length; i++) {
				var descriptor = Object.getOwnPropertyDescriptor(this, keys[i])

				if (descriptor.value && descriptor.value.__cs_clone) {
					descriptor.value = descriptor.value.__cs_clone(remaining)
				}

				Object.defineProperty(result, keys[i], descriptor)
			}
		} else {
			for (var i = 0; i < keys.length; i++) {
				Object.defineProperty(result, keys[i], Object.getOwnPropertyDescriptor(this, keys[i]))
			}
		}

		/* TODO: Check for Frozen, Sealed, Non-Extensible? */

		return result
	}

	Object.defineProperty(Object.prototype, '__cs_clone', { value: Aurora.object.clone })
	Object.defineProperty(Array.prototype, '__cs_clone', { value: Array.prototype.slice })

	var cloneTypedArray = function (depth) {
		if (depth > 1) {
			var result = new this.constructor(this.length)
			
			result.set(this)
			
			return result
		} else {
			return this.subarray(0)
		}
	}

	Object.defineProperty(Uint8Array.prototype, '__cs_clone', { value: cloneTypedArray })
	Object.defineProperty(Uint8ClampedArray.prototype, '__cs_clone', { value: cloneTypedArray })
	Object.defineProperty(Uint16Array.prototype, '__cs_clone', { value: cloneTypedArray })
	Object.defineProperty(Uint32Array.prototype, '__cs_clone', { value: cloneTypedArray })

	Object.defineProperty(Int8Array.prototype, '__cs_clone', { value: cloneTypedArray })
	Object.defineProperty(Int16Array.prototype, '__cs_clone', { value: cloneTypedArray })
	Object.defineProperty(Int32Array.prototype, '__cs_clone', { value: cloneTypedArray })

	Object.defineProperty(Float32Array.prototype, '__cs_clone', { value: cloneTypedArray })
	Object.defineProperty(Float64Array.prototype, '__cs_clone', { value: cloneTypedArray })

	Object.defineProperty(Date.prototype, '__cs_clone', { value: function () {
		return new Date(this)
	}})

	Aurora.extend = function (type, name, privateProperties, properties) {
		var result = Object.create(Object.getPrototypeOf(type))
		var keys = Object.getOwnPropertyNames(type), dollar = type.$.__cs_clone(2)

		for (var i = 0; i < keys.length; i++) {
			if (keys[i] != '$' && keys[i] != 'typename') {
				Object.defineProperty(result, keys[i], Object.getOwnPropertyDescriptor(type, keys[i]))
			}
		}

		Object.defineProperties(result, properties || {})
		Object.defineProperties(dollar, privateProperties || {})

		Object.defineProperty(result, '$', { value: dollar })
		Object.defineProperty(result, 'typename', { value: name, enumerable: true })

		return result
	}
}(this)