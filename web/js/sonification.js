const AudioContextFunc = window.AudioContext || window.webkitAudioContext;
let audioContext; // = new AudioContextFunc();
let audio_player; //= new WebAudioFontPlayer();
const orchestra = [], drum_kit = [];
let max_volume = .75, tempo = .4;
let note_queue = [];
let envelopes = [];
function setTempo(t) { tempo = t/100; console.log("Tempo: " + tempo); }
function initAudio(callback) {
  audioContext = new AudioContextFunc();
  audio_player = new WebAudioFontPlayer();
  callback();
}

function setInstrument(type,patch,callback) {
  let info = audio_player.loader.instrumentInfo(audio_player.loader.findInstrument(patch));
  console.log("Info: " + JSON.stringify(info));
  audio_player.loader.startLoad(audioContext, info.url, info.variable);
  audio_player.loader.waitLoad(function () {
    orchestra[type] = window[info.variable];
    callback(type,patch);
  });
}

function setDrumKit(type,patch,callback) {
  let info = audio_player.loader.drumInfo(audio_player.loader.findDrum(patch));
  console.log(JSON.stringify(info));
  audio_player.loader.startLoad(audioContext, info.url, info.variable);
  audio_player.loader.waitLoad(function () {
    drum_kit[type] = { pitch: info.pitch, preset: window[info.variable] };
    callback(type,patch);
  });
}

function playNote(i,t,p,d,volume) {
  if (volume > 0) {
    return audio_player.queueWaveTable(audioContext, audioContext.destination, orchestra[i],
      audioContext.currentTime + t, p,tempo * d,volume > max_volume ? max_volume : volume);
  }
  else return null;
}

function playMelody(i,t,p,volume) {
  if (volume > 0) {
    if (envelopes[i]) envelopes[i].cancel();
    envelopes[i] = audio_player.queueWaveTable(audioContext, audioContext.destination, orchestra[i],
        audioContext.currentTime + t, p,999,volume > max_volume ? max_volume : volume);
  }
}

function playChord(i,t,pitches,d,volume) {
  if (volume > 0) {
    return audio_player.queueChord(audioContext, audioContext.destination, orchestra[i],
      audioContext.currentTime + t, pitches,tempo * d,volume > max_volume ? max_volume : volume);
  }
  else return null;
}

function playDrum(i,t,d,volume) {
  if (volume > 0) {
    return audio_player.queueWaveTable(audioContext, audioContext.destination, drum_kit[i].preset,
        audioContext.currentTime + t, drum_kit[i].pitch, 1, volume > max_volume ? max_volume : volume);
  }
  else return null;
}

function addChordToQueue(i,pitches,d,v) { note_queue.push({ instrument: i, pitches: pitches, duration: d * 1000, volume: v }); }
function addNoteToQueue(i,p,d,v) { note_queue.push({ instrument: i, pitches: [p], duration: d * 1000, volume: v }); }
function melodizer() {
  if (note_queue.length > 0) {
    let note = note_queue.pop(); //console.log("waiting: " + (tempo * note.duration));
    for (let i=0;i<note.pitches.length;i++) playNote(note.instrument,0,note.pitches[i],note.duration/1000,note.volume);
    setTimeout(() => melodizer(),note.pitches.length > 1 ? 25 : tempo * note.duration);
  }
  else setTimeout(() => melodizer(),50);
}
