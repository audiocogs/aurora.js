import Muxer from './Muxer';

const MAX_DATA_LENGTH = 4294967295 - 100;
const FORMATS = {
  lpcm: 1,
  alaw: 6,
  ulaw: 7
};

export default class WAVMuxer extends Muxer {
  writeHeader() {
    let track = this.tracks[0];
    this.len = 0;
    
    this.stream.writeString('RIFF');
    this.stream.writeUInt32(0, true); // length
    this.stream.writeString('WAVE');
    this.stream.writeString('fmt ');
    this.stream.writeUInt32(16, true);
    this.stream.writeUInt16(track.format.floatingPoint ? 3 : FORMATS[track.format.formatID], true);
    this.stream.writeUInt16(track.format.channelsPerFrame, true);
    this.stream.writeUInt32(track.format.sampleRate, true);
    this.stream.writeUInt32(0, true);
    this.stream.writeUInt16(0, true);
    this.stream.writeUInt16(track.format.bitsPerChannel, true);
    this.stream.writeString('data');
    this.stream.writeUInt32(MAX_DATA_LENGTH, true); // length
  }
  
  writeData(track, chunk) {
    this.stream.writeBuffer(chunk);
    this.len += chunk.length;
  }
  
  writeTrailer() {
    console.log('write trailer')
    // this.stream.seek(4);
    // this.stream.writeUInt32(this.len + 44);
    //
    // this.stream.seek(40);
    // this.stream.writeUInt32(this.len);
  }
}
