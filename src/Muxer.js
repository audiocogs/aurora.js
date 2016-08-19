import {Readable} from 'stream';
import {StreamWriter} from 'binary-io';

export default class Muxer extends Readable {
  constructor(options = {}) {
    super();
    
    this.tracks = [];
    this.metadata = options.metadata || {};
    
    this.stream = new StreamWriter(options.stream || this);
    this._needsRead = false;
    
    this.init(options);
  }
  
  init(options) {}
  writeHeader() {}
  writeData(track, buffer) {}
  writeTrailer() {}
  
  addTrack(track) {
    if (track._demuxer) {
      throw new Error('A Track cannot be attached to both a demuxer and a muxer.');
    }
    
    if (track._muxer) {
      throw new Error('A Track can only be attached to one muxer.');
    }
    
    track.id = this.tracks.length;
    track._muxer = this;
    
    this.tracks.push(track);
  }
  
  write(buffer) {
    this.push(buffer);
  }
  
  end() {
    this.push(null);
  }
  
  _read() {
    if (!this._wroteHeader) {
      this.writeHeader();
      this._wroteHeader = true;
    }
    
    // Find the track with a buffer at the earliest time
    let chosenTrack = null;
    for (let track of this.tracks) {
      // If there is no chunk available, wait for more data
      if (!track._writeChunk) {
        // Ignore this track if it is already finished
        if (track._writableState.finished) {
          continue;
        }
        
        this._needsRead = true;
        return;
      }
      
      if (!chosenTrack || (track._writeChunk.time < chosenTrack._writeChunk.time)) {
        chosenTrack = track;
      }
    }
    
    if (chosenTrack) {
      let {_writeChunk: chunk, _writeCallback: callback} = chosenTrack;
      chosenTrack._writeChunk = null;
      chosenTrack._writeCallback = null;
      
      setImmediate(() => {
        this.writeData(chosenTrack, chunk);
        callback();
      });
    } else {
      this.writeTrailer();
      this.stream.end();
    }
    
    this._needsRead = false;
  }
}
