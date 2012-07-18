void function (global) {
	'use strict'

	var buffer = Aurora.extend(Aurora.object, 'Aurora::Buffer')

	buffer.constructor = function (data, offset, byteLength) {
		Aurora.object.constructor.apply(this)

		var off = offset ? offset : 0

		if (!byteLength || byteLength > data.byteLength - off) {
			this.view = new DataView(data, off)
		} else {
			this.view = new DataView(data, off, byteLength)
		}

		this.$.data = data

		this.length = this.view.byteLength
	}

	buffer.constructor.allocate = function (n) {
		return new Aurora.Buffer(new ArrayBuffer(n))
	}

	buffer.slice = function (position, length) {
		if (position == 0 && length >= this.length) {
			return new Aurora.Buffer(this.$.data)
		} else {
			return new Aurora.Buffer(this.$.data, position, length)
		}
	}

	/* TODO: Is this really the right place for blob work? */
	buffer.constructor.makeBlobURL = function (data) {
		return URL.createObjectURL(new Blob([data]))
	}

	buffer.constructor.revokeBlobURL = function (url) {
		URL.revokeBlobURL(url)
	}

	Aurora.buffer = buffer
	Aurora.Buffer = buffer.constructor

	Aurora.Buffer.prototype = buffer
}(this)
