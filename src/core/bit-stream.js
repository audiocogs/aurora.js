void function (global) {
	'use strict'

	var bitMask = [
		0x00000000, 0x00000001, 0x00000003, 0x00000007,
		0x0000000f, 0x0000001f, 0x0000003f, 0x0000007f,
		0x000000ff, 0x000001ff, 0x000003ff, 0x000007ff,
		0x00000fff, 0x00001fff, 0x00003fff, 0x00007fff,
		0x0000ffff, 0x0001ffff, 0x0003ffff, 0x0007ffff,
		0x000fffff, 0x001fffff, 0x003fffff, 0x007fffff,
		0x00ffffff, 0x01ffffff, 0x03ffffff, 0x07ffffff,
		0x0fffffff, 0x1fffffff, 0x3fffffff, 0x7fffffff,
		0xffffffff
	]

	var bitStream = Aurora.extend(Aurora.object, 'Aurora::BitStream', {
		bitPosition: { value: 0, writable: true },
		offset: { get: function () { return 8 * this.stream.offset + this.bitPosition } }
	})

	bitStream.constructor = function (stream) {
		Aurora.object.constructor.apply(this)

		this.$.stream = stream
	}
	
	bitStream.available = function (n) {
		return this.$.stream.available((n + 8 - this.$.bitPosition) / 8)
	}

	bitStream.advance = function (n) {
		this.$.bitPosition += n

		this.$.stream.advance(this.$.bitPosition >> 3)
		this.$.bitPosition &= 7

		return this
	}

	bitStream.align = function () {
		if (this.$.bitPosition != 0) {
			this.$.bitPosition = 0; this.$.stream.advance(1)
		}

		return this
	}

	bitStream.peekBig = function (n) {
		if (n == 0) { return 0 }

		var a0 = this.$.stream.peekUInt8(0) * 0x0100000000
		var a1 = this.$.stream.peekUInt8(1) * 0x0001000000
		var a2 = this.$.stream.peekUInt8(2) * 0x0000010000
		var a3 = this.$.stream.peekUInt8(3) * 0x0000000100
		var a4 = this.$.stream.peekUInt8(4) * 0x0000000001

		var a = a0 + a1 + a2 + a3 + a4
		a = a % Math.pow(2, 40 - this.$.bitPosition)
		a = a / Math.pow(2, 40 - this.$.bitPosition - n)
		
		return a << 0
	}

	bitStream.peek = function (n) {
		if (n == 0) { return 0 }

		var a = this.$.stream.peekUInt32(0)

		return (a << this.$.bitPosition) >>> (32 - n)
	}

	bitStream.peekSmall = function (n) {
		if (n == 0) { return 0 }

		var a = this.$.stream.peekUInt16(0)

		return ((a << this.$.bitPosition) & 0xFFFF) >>> (16 - n)
	}

	bitStream.peekOne = function (n) {
		var a = this.$.stream.peekUInt8(0)

		return ((a << this.$.bitPosition) & 0xFF) >>> 7
	}

	bitStream.readBig = function (n) {
		var value = this.peekBig(bits)

		this.advance(n)

		return value
	}

	bitStream.readSigned = function (n) {
		if (n == 0) { return 0 }

		var a = this.$.stream.peekUInt32(0)

		a = (a << this.$.bitPosition) >> (32 - n)

		this.advance(bits)

		return a
	}

	bitStream.read = function (n) {
		if (n == 0) { return 0 }

		var a = this.$.stream.peekUInt32(0)

		a = (a << this.$.bitPosition) >>> (32 - n)

		this.advance(bits)

		return a
	}

	bitStream.readSmall = function (n) {
		if (n == 0) { return 0 }

		var a = this.$.stream.peekUInt16(0)
		a = ((a << this.$.bitPosition) & 0xFFFF) >>> (32 - n)

		this.advance(bits)

		return a
	}

	bitStream.readOne = function () {
		var a = this.$.stream.peekUInt8(0)
		a = ((a << this.$.bitPosition) & 0xFF) >>> 7
	}

	bitStream.readLSB = function (n) {
		if (n == 0) { return 0 }

		var modBits = n + this.$.bitPosition

		var a = this.$.stream.peekUInt8(0) >>> this.$.bitPosition

		if (modBits > 8) {
			a = a | (this.$.stream.peekUInt8(1) << (8  - this.$.bitPosition))
		}

		if (modBits > 16) {
			a = a | (this.$.stream.peekUInt8(2) << (16 - this.$.bitPosition))
		}

		if (modBits > 24) {
			a = a | (this.$.stream.peekUInt8(3) << (24 - this.$.bitPosition))
		}

		if (modBits > 32) {
			a = a | (this.$.stream.peekUInt8(4) << (32 - this.$.bitPosition))
		}

		this.advance(n)

		return a & bitMask[n]
	}

	Aurora.bitStream = bitStream
	Aurora.BitStream = bitStream.constructor

	Aurora.BitStream.prototype = bitStream
}(this)
