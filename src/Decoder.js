import {Duplex} from 'stream';
import {BufferList, Stream, Bitstream, UnderflowError} from 'stream-reader';

const codecs = {};

/**
 * This is the base transform stream class for all decoders.
 * We implement our own transform stream here instead of using
 * the one built-in one so that we don't have to decode
 * the entire input buffer at once. Given that compressed media
 * formats output more data than they are input, this helps spread 
 * the decoding work out over time.
 *
 * Subclasses should implement the `decodePacket` method.
 */
export default class Decoder extends Duplex {
  constructor(format) {
    super();
    
    this.format = format;
    this.list = new BufferList;
    this.stream = new Stream(this.list);
    this.bitstream = new Bitstream(this.stream);
    
    this.init();
    
    // TODO: remove `setCookie` and just do it in `init`?
    if (format.cookie) {
      this.setCookie(format.cookie);
    }
    
    // This should cause a read roughly once a second
    this._readableState.highWaterMark = format.sampleRate * format.channelsPerFrame * 4;
    this._readableState.needReadable = true;
    
    this.once('prefinish', () => {
      this.push(null);
    });
  }
  
  _write(chunk, encoding, callback) {
    this.list.append(chunk, callback);
    
    // Trigger a read if needed
    let rs = this._readableState;
    if (rs.needReadable || rs.length < rs.highWaterMark) {
      this._read(rs.highWaterMark);
    }
  }
  
  _read(n) {
    let rs = this._readableState;
    let read = 0;
    
    // Read packets until we fill the requested number of bytes
    while (this.list.availableBytes > 0 && read < n) {
      let offset = this.bitstream.offset();
      let packet = null;
      
      try {
        packet = this.decodePacket();
      } catch (err) {
        if (!(err instanceof UnderflowError)) {
          return callback(err);
        }
      }
      
      // If a packet was successfully decoded, add it to the output buffer.
      // Otherwise, jump back to the last known good offset, and try again
      // when we have more data available.
      if (packet) {
        let buf = new Buffer(packet.buffer)
        read += buf.length;
        this.push(buf);
      } else {
        this.bitstream.seek(offset);
      
        rs.needReadable = true;
        this.list.callback(this.list.last);
        break;
      }
    }
  }
  
  // Subclasses should implement these methods
  init() {}
  setCookie(cookie) {}
  
  // TODO: remove. Use decodePacket.
  readChunk() {}
  
  decodePacket() {
    return this.readChunk(); // backwards compatibility.
  }
  
  static register(id, decoder) {
    codecs[id] = decoder;
  }
  
  static find(id) {
    return codecs[id] || null;
  }
}
