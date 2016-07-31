import {Writable} from 'stream';
import {BufferList, Stream, UnderflowError} from 'stream-reader';
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
    this._needsRead = 0;
    
    this.list = new BufferList;
    this.stream = new Stream(this.list);
    this.tracks = [];
    
    this.init();
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
    while (this.stream.remainingBytes() > 0 && (!this._startedData || this._needsRead)) {
      let offset = this.stream.offset;
      
      try {
        this.readChunk();
      } catch (err) {
        // If we hit an underflow, seek back to the start of 
        // the chunk and try again when we have more data.
        if (err instanceof UnderflowError) {
          this.stream.seek(offset);
          this.list.callback();
        } else {
          this.emit('error', err);
        }
        
        return;
      }
    }
    
    // End all of the tracks at the end of the input
    if (this._writableState.finished && this.stream.remainingBytes() === 0) {
      for (let track of this.tracks) {
        track.end();
      }
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
