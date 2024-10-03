enum PieceStyle  {
  cburnett,
  merida,
  pirouetti,
  chessnut,
  chess7,
  alpha,
  reillycraig,
  companion,
  riohacha,
  kosal,
  leipzig,
  fantasy,
  spatial,
  celtic,
  california,
  caliente,
  pixel,
  maestro,
  fresca,
  cardinal,
  gioco,
  tatiana,
  staunty,
  governor,
  dubrovny,
  icpieces,
  libra,
  mpchess,
  shapes,
  kiwenSuwi,
  horsey,
  anarcandy,
  letter,
  disguised,
  symmetric;
}

enum GameStyle {
  bullet,blitz,rapid,classical
}

enum MidiBank {
  piano,chromaticPerc,organ,guitar,bass,strings,ensemble,brass,reed,pipe,synthLead,synthPad,synthFX,ethnic,perc,soundFX
}
enum MidiInstrument {
  acousticGrandPiano(MidiBank.piano),
  brightAcousticPiano(MidiBank.piano),
  electricGrandPiano(MidiBank.piano),
  honkyTonkPiano(MidiBank.piano),
  electricPiano1(MidiBank.piano),
  electricPiano2(MidiBank.piano),
  harpsichord(MidiBank.piano),
  clavinet(MidiBank.piano),
  celesta(MidiBank.chromaticPerc),
  glockenspiel(MidiBank.chromaticPerc),
  musicBox(MidiBank.chromaticPerc),
  marimba(MidiBank.chromaticPerc),
  vibraphone(MidiBank.chromaticPerc),
  xylophone(MidiBank.chromaticPerc),
  tubularBells(MidiBank.chromaticPerc),
  dulcimer(MidiBank.chromaticPerc),
  drawBarOrgan(MidiBank.organ),
  percOrgan(MidiBank.organ),
  rockOrgan(MidiBank.organ),
  churchOrgan(MidiBank.organ),
  reedOrgan(MidiBank.organ),
  accordion(MidiBank.organ),
  harmonica(MidiBank.organ),
  tangoAccordion(MidiBank.organ),
  acousticGuitarNylon(MidiBank.guitar),
  acousticGuitarSteel(MidiBank.guitar),
  electricGuitarJazz(MidiBank.guitar),
  electricGuitarClean(MidiBank.guitar),
  electricGuitarMuted(MidiBank.guitar),
  overdrivenGuitar(MidiBank.guitar),
  distortionGuitar(MidiBank.guitar),
  guitarHarmonics(MidiBank.guitar),
  acousticBass(MidiBank.bass),
  electricBassFinger(MidiBank.bass),
  electricBassPick(MidiBank.bass),
  fretkessBass(MidiBank.bass),
  slapBass1(MidiBank.bass),
  slapBass2(MidiBank.bass),
  synthBass1(MidiBank.bass),
  synthBass2(MidiBank.bass),
  violin(MidiBank.strings),
  viola(MidiBank.strings),
  cello(MidiBank.strings),
  contrabass(MidiBank.strings),
  tremoloStrings(MidiBank.strings),
  pizzStrings(MidiBank.strings),
  orchHarp(MidiBank.strings),
  timpani(MidiBank.strings), //why is this strings?
  stringEnsemble1(MidiBank.ensemble),
  stringEnsemble2(MidiBank.ensemble),
  synthStrings1(MidiBank.ensemble),
  synthStrings2(MidiBank.ensemble),
  choirAahs(MidiBank.ensemble),
  choirOohs(MidiBank.ensemble),
  synthChoir(MidiBank.ensemble),
  orchHit(MidiBank.ensemble),
  trumpet(MidiBank.brass),
  trombone(MidiBank.brass),
  tuba(MidiBank.brass),
  mutedTrumpet(MidiBank.brass),
  frenchHorn(MidiBank.brass),
  brassSection(MidiBank.brass),
  synthBrass1(MidiBank.brass),
  synthBrass2(MidiBank.brass),
  sopranoSax(MidiBank.reed),
  altoSax(MidiBank.reed),
  tenorSax(MidiBank.reed),
  baritoneSax(MidiBank.reed),
  oboe(MidiBank.reed),
  englishHorn(MidiBank.reed),
  bassoon(MidiBank.reed),
  clarinet(MidiBank.reed),
  piccolo(MidiBank.pipe),
  flute(MidiBank.pipe),
  recorder(MidiBank.pipe),
  panFlute(MidiBank.pipe),
  blownBottle(MidiBank.pipe),
  shakuhachi(MidiBank.pipe),
  whistle(MidiBank.pipe),
  ocarina(MidiBank.pipe),
  lead1Square(MidiBank.synthLead),
  lead2Sawtooth(MidiBank.synthLead),
  lead3Calliope(MidiBank.synthLead),
  lead4Chiff(MidiBank.synthLead),
  lead5Charang(MidiBank.synthLead),
  lead6Voice(MidiBank.synthLead),
  lead7Fifths(MidiBank.synthLead),
  lead8BassAndLead(MidiBank.synthLead),
  pad1NewAge(MidiBank.synthPad),
  pad2Warm(MidiBank.synthPad),
  pad3Polysynth(MidiBank.synthPad),
  pad4Chior(MidiBank.synthPad),
  pad5Bowed(MidiBank.synthPad),
  pad6Metallic(MidiBank.synthPad),
  pad7Halo(MidiBank.synthPad),
  pad8Sweep(MidiBank.synthPad),
  fx1Rain(MidiBank.synthFX),
  fx2Soundtrack(MidiBank.synthFX),
  fx3Crystal(MidiBank.synthFX),
  fx4Atmosphere(MidiBank.synthFX),
  fx5Brightness(MidiBank.synthFX),
  fx6Goblins(MidiBank.synthFX),
  fx7Echoes(MidiBank.synthFX),
  fx8SciFi(MidiBank.synthFX),
  sitar(MidiBank.ethnic),
  banjo(MidiBank.ethnic),
  shamisen(MidiBank.ethnic),
  koto(MidiBank.ethnic),
  kalimba(MidiBank.ethnic),
  bagpipe(MidiBank.ethnic),
  fiddle(MidiBank.ethnic),
  shanai(MidiBank.ethnic),
  tinkleBell(MidiBank.perc),
  agogo(MidiBank.perc),
  steelDrums(MidiBank.perc),
  woodBlock(MidiBank.perc),
  taikoDrum(MidiBank.perc),
  melodicTom(MidiBank.perc),
  synthDrum(MidiBank.perc),
  reverseCymbal(MidiBank.perc),
  guitarFretNoise(MidiBank.soundFX),
  breathNoise(MidiBank.soundFX),
  seashore(MidiBank.soundFX),
  birdTweet(MidiBank.soundFX),
  telephoneRing(MidiBank.soundFX),
  helicopter(MidiBank.soundFX),
  applause(MidiBank.soundFX),
  gunshot(MidiBank.soundFX);
    final MidiBank bank;
    const MidiInstrument(this.bank);
  }

  enum MidiDrum {
    bassDrum1(35),
    bassDrum2(36),
    rimshot(37),
    snareDrum1(38),
    handClap(39),
    snareDrum2(40),
    lowTom2(41),
    closedHiHat(42),
    lowTom1(43),
    pedalHiHat(44),
    midTom2(45),
    openHiHat(46),
    midTom1(47),
    highTom2(48),
    crashCymbal1(49),
    highTom1(50),
    rideCymbal1(51),
    chineseCymbal(52),
    rideBell(53),
    tambourine(54),
    splashCymbal(55),
    cowBell(56),
    crashCymbal2(57),
    vibraSlap(58),
    rideCymbal2(59),
    highBongo(60),
    lowBongo(61),
    muteHighConga(62),
    openHighConga(63),
    lowConga(64),
    highTimbale(65),
    lowTimbale(66),
    highAgogo(67),
    lowAgogo(68),
    cabasa(69),
    meracas(70),
    shortWhistle(71),
    longWhistle(72),
    shortGuiro(73),
    longGuiro(74),
    claves(75),
    highWoodBlock(76),
    lowWoodBlock(77),
    muteCuica(78),
    openCuica(79),
    muteTriangle(80),
    openTriangle(81);
  final int patchNum;
  const MidiDrum(this.patchNum);
}

//const lichessToken = "lip_WnPKLoSmxaa5NW60hcj5"; //"lip_v6Jc4xJ9VmIgIT3mUawi";

