let sharedContext = null;

class WebAudioSink extends WebAudioStream {
  constructor(sampleRate, channels) {
    super(sampleRate, channels);
    
    let context = sharedContext || (sharedContext = new AudioContext);
    this.connect(context.destination);
  }
  
  destroy() {
    this.disconnect();
  }
  
  getDeviceTime() {
    return this.context.currentTime * this.sampleRate;
  }
}
