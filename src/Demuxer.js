import {Writable} from 'stream';
import {BufferList, Stream} from 'stream-reader';
import Track from './Track';

const formats = [];

/**
 * This is the base class for all demuxers.
 * Demuxers are writable streams that emit 'track' 
 * events with Track objects. Each Track is a readable
 * stream representing the data for a single track in the media.
 */
export default class Demuxer extends Writable {
  constructor() {
    super();
    
    this._startedData = false;
    this._needsRead = false;
    
    this.list = new BufferList;
    this.stream = new Stream(this.list);
    this.tracks = [];
    
    this.init();
    
    // End all of the tracks at the end of the input
    this.once('prefinish', () => {
      for (let track of this.tracks) {
        track.end();
      }
    });
  }
  
  static probe(buffer) {
    throw new Error('Not implemented');
  }
  
  addTrack(track) {
    track._demuxer = this;
    this.tracks.push(track);
    this.emit('track', track);
    return track;
  }
  
  _write(buffer, encoding, callback) {
    this.list.append(buffer, callback);
    
    // If tracks haven't started emitting data yet, 
    // or we are waiting, trigger one right away.
    if (!this._startedData || this._needsRead) {
      setImmediate(() => {
        this._readChunk();
      });
    }
  }
  
  _readChunk() {
    // Nothing available, wait until we have more data
    if (this.list.availableBytes === 0) {
      this._needsRead = true;
      return;
    }
    
    var res = this.readChunk();
    if (res === false) {
      // Not enough data. Wait for more.
      this._needsRead = true;
      this.list.callback();
    } else {
      this._needsRead = false;
    }
  }
  
  init() {}
  readChunk() {}
  
  static register(demuxer) {
    formats.push(demuxer);
  }
  
  static find(buffer) {
    let stream = Stream.fromBuffer(buffer);
    
    for (let format of formats) {
      let offset = stream.offset;
      try {
        if (format.probe(buffer)) {
          return format;
        }
      } catch (err) {
        // an underflow or other error occurred
      }
      
      stream.seek(offset);
    }
    
    return null;
  }
}
