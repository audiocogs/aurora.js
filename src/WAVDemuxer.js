import Demuxer from './Demuxer';
import Track from './Track';

const formats = { 
  0x0001: 'lpcm',
  0x0003: 'lpcm',
  0x0006: 'alaw',
  0x0007: 'ulaw'
};

export default class WAVDemuxer extends Demuxer {  
  static probe(buffer) {
    return buffer.peekString(0, 4) === 'RIFF' && 
           buffer.peekString(8, 4) === 'WAVE';
  }
                
  readChunk() {
    if (!this.type) {
      this.type = this.stream.readString(4);
      this.len = this.stream.readUInt32(true); // little endian
    }
    
    switch (this.type) {
      case 'RIFF':
        if (this.stream.readString(4) !== 'WAVE') {
          throw new Error('Invalid WAV file.');
        }
        
        break;
        
      case 'fmt ':
        let encoding = this.stream.readUInt16(true);
        if (!(encoding in formats)) {
          throw new Error('Unsupported format in WAV file.');
        }
          
        this.format = {
          formatID: formats[encoding],
          floatingPoint: encoding === 0x0003,
          littleEndian: formats[encoding] === 'lpcm',
          channelsPerFrame: this.stream.readUInt16(true),
          sampleRate: this.stream.readUInt32(true),
          framesPerPacket: 1
        };
          
        this.stream.advance(4); // bytes/sec.
        this.stream.advance(2); // block align
        
        this.format.bitsPerChannel = this.stream.readUInt16(true);
        this.format.bytesPerPacket = (this.format.bitsPerChannel / 8) * this.format.channelsPerFrame;
        
        // Advance to the next chunk
        this.stream.advance(this.len - 16);
        break;
        
      case 'data':
        if (this.tracks.length === 0) {
          let bytes = this.format.bitsPerChannel / 8;
          let duration = this.len / bytes / this.format.channelsPerFrame / this.format.sampleRate * 1000 | 0;
          this.addTrack(new Track(Track.AUDIO, this.format, duration));
        }
        
        let buffer = this.stream.readSingleBuffer(this.len);
        this.len -= buffer.length;
        this.tracks[0].write(buffer);
        break;
        
      default:
        this.stream.advance(this.len);
    }
          
    if (this.type !== 'data' || this.len === 0) {
      this.type = null;
    }
  }
}

Demuxer.register(WAVDemuxer);
