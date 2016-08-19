import {Writable} from 'stream';
import {BufferList} from 'binary-io';

class WebAudioStream extends Writable {
  constructor(format) {
    super();
    
    this.format = format;
    this.context = null;
    this.node = null;
    
    this.list = new BufferList;
    this.stream = new Stream(this.list);
  }
  
  connect(dest) {
    if (this.node) {
      this.disconnect();
    }
    
    this.context = dest.context;
    this.node = this.context.createScriptProcessor(0, 0, this.format.channelsPerFrame);
    this.node.onaudioprocess = this.refill.bind(this);
    
    this.bufferSize = Math.ceil(this.node.bufferSize / (this.context.sampleRate / this.format.sampleRate) * this.format.channelsPerFrame);
    this.bufferSize += this.bufferSize % this.format.channelsPerFrame;
    
    if (this.context.sampleRate !== this.format.sampleRate) {
      this.resampler = new Resampler(this.format.sampleRate, this.context.sampleRate, this.format.channelsPerFrame, this.bufferSize);
    }
    
    this.node.connect(dest);
  }
  
  disconnect() {
    if (this.node) {
      this.node.disconnect();
      this.node = null;
      this.context = null;
      this.resampler = null;
    }
  }
  
  _write(chunk, encoding, callback) {
    this.list.append(chunk, callback);
  }
  
  refill(event) {
    let outputBuffer = event.outputBuffer;
    let channelCount = outputBuffer.numberOfChannels;
    let channels = new Array(channelCount);
    
    for (let i = 0; i < channelCount; i++) {
      channels[i] = outputBuffer.getChannelData(i);
    }
    
    let buf = this.stream.readBuffer(this.bufferSize * 4);
    let data = new Float32Array(buf.buffer);
    
    if (this.resampler) {
      data = this.resampler.resample(data);
    }
    
    for (let i = 0; i < outputBuffer.length; i++) {
      for (let n = 0; n < channelCount; n++) {
        channels[n][i] = data[i * channelCount + n];
      }
    }
  }
}
