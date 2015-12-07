/*
 * This resampler is from XAudioJS: https://github.com/grantgalitz/XAudioJS
 * Planned to be replaced with src.js, eventually: https://github.com/jussi-kalliokoski/src.js
 */

//JavaScript Audio Resampler (c) 2011 - Grant Galitz
function Resampler(fromSampleRate, toSampleRate, channels, outputBufferSize, noReturn) {
	this.fromSampleRate = fromSampleRate;
	this.toSampleRate = toSampleRate;
	this.channels = channels | 0;
	this.outputBufferSize = outputBufferSize;
	this.noReturn = !!noReturn;
	this.initialize();
}

Resampler.prototype.initialize = function () {
	//Perform some checks:
	if (this.fromSampleRate > 0 && this.toSampleRate > 0 && this.channels > 0) {
		if (this.fromSampleRate == this.toSampleRate) {
			//Setup a resampler bypass:
			this.resampler = this.bypassResampler;		//Resampler just returns what was passed through.
			this.ratioWeight = 1;
		}
		else {
			if (this.fromSampleRate < this.toSampleRate) {
				/*
					Use generic linear interpolation if upsampling,
					as linear interpolation produces a gradient that we want
					and works fine with two input sample points per output in this case.
				*/
				this.useLinearInterpolationFunction();
				this.lastWeight = 1;
			}
			else {
				/*
					Custom resampler I wrote that doesn't skip samples
					like standard linear interpolation in high downsampling.
					This is more accurate than linear interpolation on downsampling.
				*/
				this.useMultiTapFunction();
				this.tailExists = false;
				this.lastWeight = 0;
			}
			this.ratioWeight = this.fromSampleRate / this.toSampleRate;
			this.initializeBuffers();
		}
	}
	else {
		throw(new Error("Invalid settings specified for the resampler."));
	}
};

Resampler.prototype.useLinearInterpolationFunction = function () {
	/**
	 * Special case for 2 channels, allows optimize computations. Obtained from generic function
	 */
	if (this.channels == 2) {
		this.resampler = function (buffer) {
			var bufferLength = buffer.length;
			var outLength = this.outputBufferSize;
			if (bufferLength % 2 == 0) {
				if (bufferLength > 0) {
					var ratioWeight = this.ratioWeight;
					var weight = this.lastWeight;
					var firstWeight = 0;
					var secondWeight = 0;
					var sourceOffset = 0;
					var outputOffset = 0;
					var outputBuffer = this.outputBuffer;
					for (; weight < 1; weight += ratioWeight) {
						secondWeight = weight % 1;
						firstWeight = 1 - secondWeight;
						outputBuffer[outputOffset++] = (this.lastOutput[0] * firstWeight) + (buffer[0] * secondWeight);
						outputBuffer[outputOffset++] = (this.lastOutput[1] * firstWeight) + (buffer[1] * secondWeight);
					}
					weight -= 1;
					for (bufferLength -= 2, sourceOffset = Math.floor(weight) * 2; outputOffset < outLength && sourceOffset < bufferLength;) {
						secondWeight = weight % 1;
						firstWeight = 1 - secondWeight;
						outputBuffer[outputOffset++] = (buffer[sourceOffset] * firstWeight) + (buffer[sourceOffset + 2] * secondWeight);
						outputBuffer[outputOffset++] = (buffer[sourceOffset + 1] * firstWeight) + (buffer[sourceOffset + 3] * secondWeight);
						weight += ratioWeight;
						sourceOffset = Math.floor(weight) * 2;
					}
					this.lastOutput[0] = buffer[sourceOffset++];
					this.lastOutput[1] = buffer[sourceOffset];
					this.lastWeight = weight % 1;
					return this.bufferSlice(outputOffset);
				} else {
					return this.noReturn ? 0 : [];
				}
			} else {
				throw(new Error("Buffer was of incorrect sample length."));
			}
		};
	/**
	 * Generic function for any other number of channels
	 */
	} else {
		this.resampler = function (buffer) {
			var bufferLength = buffer.length;
			var outLength = this.outputBufferSize;
			if ((bufferLength % this.channels) == 0) {
				if (bufferLength > 0) {
					var ratioWeight = this.ratioWeight;
					var weight = this.lastWeight;
					var firstWeight = 0;
					var secondWeight = 0;
					var sourceOffset = 0;
					var outputOffset = 0;
					var outputBuffer = this.outputBuffer;
					var channel = 0;
					for (; weight < 1; weight += ratioWeight) {
						secondWeight = weight % 1;
						firstWeight = 1 - secondWeight;
						for (channel = 0; channel < this.channels; ++channel) {
							outputBuffer[outputOffset++] = (this.lastOutput[channel] * firstWeight) + (buffer[channel] * secondWeight);
						}
					}
					weight -= 1;
					for (bufferLength -= this.channels, sourceOffset = Math.floor(weight) * this.channels; outputOffset < outLength && sourceOffset < bufferLength;) {
						secondWeight = weight % 1;
						firstWeight = 1 - secondWeight;
						for (channel = 0; channel < this.channels; ++channel) {
							outputBuffer[outputOffset++] = (buffer[sourceOffset + (channel > 0 ? channel : 0)] * firstWeight) + (buffer[sourceOffset + (this.channels + channel)] * secondWeight);
						}
						weight += ratioWeight;
						sourceOffset = Math.floor(weight) * this.channels;
					}
					for (channel = 0; channel < this.channels; ++channel) {
						this.lastOutput[channel] = buffer[sourceOffset++];
					}
					this.lastWeight = weight % 1;
					return this.bufferSlice(outputOffset);
				} else {
					return this.noReturn ? 0 : [];
				}
			} else {
				throw(new Error("Buffer was of incorrect sample length."));
			}
		};
	}
};

Resampler.prototype.useMultiTapFunction = function () {
	/**
	 * Special case for 2 channels, allows optimize computations. Obtained from generic function
	 */
	if (this.channels == 2) {
		this.resampler = function (buffer) {
			var bufferLength = buffer.length;
			var outLength = this.outputBufferSize;
			if ((bufferLength % 2) == 0) {
				if (bufferLength > 0) {
					var ratioWeight = this.ratioWeight;
					var weight = 0;
					var output0 = 0;
					var output1 = 0;
					var actualPosition = 0;
					var amountToNext = 0;
					var alreadyProcessedTail = !this.tailExists;
					this.tailExists = false;
					var outputBuffer = this.outputBuffer;
					var outputOffset = 0;
					var currentPosition = 0;
					do {
						if (alreadyProcessedTail) {
							weight = ratioWeight;
							output0 = 0;
							output1 = 0;
						} else {
							weight = this.lastWeight;
							output0 = this.lastOutput[0];
							output1 = this.lastOutput[1];
							alreadyProcessedTail = true;
						}
						while (weight > 0 && actualPosition < bufferLength) {
							amountToNext = 1 + actualPosition - currentPosition;
							if (weight >= amountToNext) {
								output0 += buffer[actualPosition++] * amountToNext;
								output1 += buffer[actualPosition++] * amountToNext;
								currentPosition = actualPosition;
								weight -= amountToNext;
							} else {
								output0 += buffer[actualPosition] * weight;
								output1 += buffer[actualPosition + 1] * weight;
								currentPosition += weight;
								weight = 0;
								break;
							}
						}
						if (weight == 0) {
							outputBuffer[outputOffset++] = output0 / ratioWeight;
							outputBuffer[outputOffset++] = output1 / ratioWeight;
						} else {
							this.lastWeight = weight;
							this.lastOutput[0] = output0;
							this.lastOutput[1] = output1;
							this.tailExists = true;
							break;
						}
					} while (actualPosition < bufferLength && outputOffset < outLength);
					return this.bufferSlice(outputOffset);
				} else {
					return this.noReturn ? 0 : [];
				}
			} else {
				throw(new Error("Buffer was of incorrect sample length."));
			}
		};
	/**
	 * Generic function for any other number of channels
	 */
	} else {
		this.resampler = function (buffer) {
			var bufferLength = buffer.length;
			var outLength = this.outputBufferSize;
			if ((bufferLength % this.channels) == 0) {
				if (bufferLength > 0) {
					var ratioWeight = this.ratioWeight;
					var weight = 0;
					var output = {};
					for (var channel = 0; channel < this.channels; ++channel) {
						output[channel] = 0;
					}
					var actualPosition = 0;
					var amountToNext = 0;
					var alreadyProcessedTail = !this.tailExists;
					this.tailExists = false;
					var outputBuffer = this.outputBuffer;
					var outputOffset = 0;
					var currentPosition = 0;
					do {
						if (alreadyProcessedTail) {
							weight = ratioWeight;
							for (channel = 0; channel < this.channels; ++channel) {
								output[channel] = 0;
							}
						} else {
							weight = this.lastWeight;
							for (channel = 0; channel < this.channels; ++channel) {
								output[channel] = this.lastOutput[channel];
							}
							alreadyProcessedTail = true;
						}
						while (weight > 0 && actualPosition < bufferLength) {
							amountToNext = 1 + actualPosition - currentPosition;
							if (weight >= amountToNext) {
								for (channel = 0; channel < this.channels; ++channel) {
									output[channel] += buffer[actualPosition++] * amountToNext;
								}
								currentPosition = actualPosition;
								weight -= amountToNext;
							} else {
								for (channel = 0; channel < this.channels; ++channel) {
									output[channel] += buffer[actualPosition + (channel > 0 ? channel : 0)] * weight;
								}
								currentPosition += weight;
								weight = 0;
								break;
							}
						}
						if (weight == 0) {
							for (channel = 0; channel < this.channels; ++channel) {
								outputBuffer[outputOffset++] = output[channel] / ratioWeight;
							}
						} else {
							this.lastWeight = weight;
							for (channel = 0; channel < this.channels; ++channel) {
								this.lastOutput[channel] = output[channel];
							}
							this.tailExists = true;
							break;
						}
					} while (actualPosition < bufferLength && outputOffset < outLength);
					return this.bufferSlice(outputOffset);
				} else {
					return this.noReturn ? 0 : [];
				}
			} else {
				throw(new Error("Buffer was of incorrect sample length."));
			}
		};
	}
};

Resampler.prototype.bypassResampler = function (buffer) {
	if (this.noReturn) {
		//Set the buffer passed as our own, as we don't need to resample it:
		this.outputBuffer = buffer;
		return buffer.length;
	}
	else {
		//Just return the buffer passsed:
		return buffer;
	}
};

Resampler.prototype.bufferSlice = function (sliceAmount) {
	if (this.noReturn) {
		//If we're going to access the properties directly from this object:
		return sliceAmount;
	}
	else {
		//Typed array and normal array buffer section referencing:
		try {
			return this.outputBuffer.subarray(0, sliceAmount);
		}
		catch (error) {
			try {
				//Regular array pass:
				this.outputBuffer.length = sliceAmount;
				return this.outputBuffer;
			}
			catch (error) {
				//Nightly Firefox 4 used to have the subarray function named as slice:
				return this.outputBuffer.slice(0, sliceAmount);
			}
		}
	}
};

Resampler.prototype.initializeBuffers = function () {
	//Initialize the internal buffer:
	try {
		this.outputBuffer = new Float32Array(this.outputBufferSize);
		this.lastOutput = new Float32Array(this.channels);
	}
	catch (error) {
		this.outputBuffer = [];
		this.lastOutput = [];
	}
};

module.exports = Resampler;
