import {Readable} from 'stream';

/**
 * A Track is a readable stream representing a single
 * track within a media container. It is attached to its
 * parent Demuxer so it can control stream backpressure.
 */
export default class Track extends Readable {
  constructor(type = Track.AUDIO, format = {}, duration = 0) {
    super();
    
    this._demuxer = null;
    this.type = type;
    this.format = format;
    this.duration = duration;
    this.seekPoints = [];
    this._discarded = false;
  }
  
  // track media types
  static AUDIO = 'audio';
  static VIDEO = 'video';
  static SUBTITLE = 'subtitle';
  static TEXT = 'text';
  
  /**
   * Marks the track for discard, so that the
   * data is not buffered in the stream when there
   * are no readers.
   */
  discard() {
    this._discarded = true;
  }
  
  /**
   * Writes data to the track. For use by demuxers.
   */
  write(chunk) {
    if (!this._demuxer) {
      throw new Error('The track must be added to a demuxer');
    }
    
    this._demuxer._startedData = true;
    
    if (!this._discarded) {
      this.push(new Buffer(chunk));
    }
  }
  
  /**
   * Ends the track. For use by demuxers.
   */
  end() {
    if (!this._readableState.ended) {
      this.push(null);
    }
  }
  
  _read() {
    setImmediate(() => {
      this._demuxer._readChunk();
    });
  }
  
  addSeekPoint(offset, timestamp) {
    let index = this.searchTimestamp(timestamp);
    return this.seekPoints.splice(index, 0, { offset, timestamp });
  }
  
  searchTimestamp(timestamp) {
    let low = 0;
    let high = this.seekPoints.length;
    
    // optimize appending entries
    if (high > 0 && this.seekPoints[high - 1].timestamp < timestamp) {
      return high;
    }
    
    while (low < high) {
      let mid = (low + high) >> 1;
      let time = this.seekPoints[mid].timestamp;
      
      if (time < timestamp) {
        low = mid + 1;
      } else if (time >= timestamp) {
        high = mid;
      }
    }
    
    if (high > this.seekPoints.length) {
      high = this.seekPoints.length;
    }
    
    return high;
  }
  
  getSeekPoint(timestamp) {
    if (this.format && this.format.framesPerPacket > 0 && this.format.bytesPerPacket > 0) {
      let seekPoint = {
        timestamp: timestamp,
        offset: this.format.bytesPerPacket * timestamp / this.format.framesPerPacket
      };
      
      return seekPoint;
    } else {
      let index = this.searchTimestamp(timestamp);
      return this.seekPoints[index];
    }
  }
  
  seek(timestamp) {
    let seekPoint = this.getSeekPoint(timestamp);
    if (!seekPoint) {
      return null;
    }
    
    // TODO: seek stream to seekPoint.offset
    
    return seekPoint.timestamp;
  }
}
