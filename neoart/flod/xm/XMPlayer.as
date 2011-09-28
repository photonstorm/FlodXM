/* FlodXM Alpha 3
   2011/09/17
   Christian Corti
   Neoart Costa Rica

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 	 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 	 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 	 IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package neoart.flod.xm {
  import flash.utils.*;
  import neoart.flod.core.*;

  public final class XMPlayer extends SBPlayer {
    internal var
      patterns     : Vector.<XMPattern>,
      instruments  : Vector.<XMInstrument>,
      amiga        : int;
    private var
      voices       : Vector.<XMVoice>,
      order        : int,
      position     : int,
      nextOrder    : int,
      nextPosition : int,
      pattern      : XMPattern,
      patternDelay : int,
      tickTemp     : int;

    public function XMPlayer(mixer:Soundblaster = null) {
      super(mixer);
    }

    override public function load(stream:ByteArray):int {
      super.load(stream);
      XMLoader.load(stream, mixer);
      if (version) setup();
      return version;
    }

    override public function process():void {
      var instrument:XMInstrument, isPorta:int, jumpFlag:int, paramx:int, paramy:int, row:XMRow, sample:XMSample, voice:XMVoice;

      if (timer == 0) {
        if (nextOrder >= 0) order = nextOrder;
        if (nextPosition >= 0) position = nextPosition;
        nextOrder = nextPosition = -1;

        pattern = patterns[track[order]];
        voice = voices[0];

        while (voice) {
          row = pattern.rows[int(position + voice.index)];

          if (voice.arpeggioOn) {
            voice.arpeggioOn = 0;
            voice.frequency = voice.period;
            voice.flags = XM.FLAG_PERIOD;
          } else if (voice.vibratoOn) {
            if (row.effect != XM.FX_VIBRATO && row.effect != XM.FX_VIBRATO_VOLUME_SLIDE) {
              voice.frequency = voice.period;
              voice.flags = XM.FLAG_PERIOD;
            } else voice.vibratoOn = 0;
          }

          paramx = row.volume >> 4;
          isPorta = int(row.effect == XM.FX_TONE_PORTAMENTO || row.effect == XM.FX_TONE_PORTAMENTO_VOLUME_SLIDE || paramx == XM.VX_TONE_PORTAMENTO);

          if (row.note == XM.NOTE_KEYOFF || (row.effect == XM.FX_KEYOFF && row.param == 0)) {
            voice.keyoff = 1
            voice.isFading = 1;
          } else {
            voice.keyoff = 0;
          }

          if (row.note && !voice.keyoff) {
            if (!isPorta) {
              voice.note = row.note - 1;
              voice.flags |= XM.FLAG_PERIOD | XM.FLAG_TRIGGER;
            }
          }

          if (row.instrument) {
            instrument = instruments[row.instrument];
            voice.sample = instrument.samples[instrument.noteSamples[voice.note]];

          if (!isPorta) {
              voice.instrument = instrument;
              voice.reset();
            } else {
              voice.volume = voice.sample.volume;
              voice.panning = voice.sample.panning;
              voice.finetune = voice.sample.finetune;
              voice.volEnvelope.reset(64);
              voice.panEnvelope.reset(32);
              voice.autoVibratoPos = 0;
              voice.autoSweepPos = 0;
              voice.flags |= (XM.FLAG_VOLUME | XM.FLAG_PANNING);
            }
          }

          instrument = voice.instrument;
          sample = voice.sample;

          if (row.note && !voice.keyoff) {
            var value:int = ((120 - (row.note + sample.relative - 1)) << 6) - ((voice.finetune >> 3) << 2);
            if (!isPorta) voice.frequency = voice.period = value;
              else voice.portaPeriod = value;
          }

          if (row.volume) {
            if (row.volume >= 16 && row.volume <= 80) {
              voice.volume = row.volume - 16;
              voice.flags |= XM.FLAG_VOLUME;
            } else {
              paramy = row.volume & 15;

              switch (paramx) {
                case XM.VX_FINE_VOLUME_SLIDE_DOWN:
                  voice.volume -= paramy;
                  if (voice.volume < 0) voice.volume = 0;
                  voice.flags |= XM.FLAG_VOLUME;
                  break;
                case XM.VX_FINE_VOLUME_SLIDE_UP:
                  voice.volume += paramy;
                  if (voice.volume > 64) voice.volume = 64;
                  voice.flags |= XM.FLAG_VOLUME;
                  break;
                case XM.VX_SET_VIBRATO_SPEED:
                  if (paramy) voice.vibratoSpeed = paramy;
                  break;
                case XM.VX_VIBRATO:
                  if (paramy) voice.vibratoDepth = paramy << 2;
                  break;
                case XM.VX_SET_PANNING:
                  voice.panning = paramy << 4;
                  voice.flags |= XM.FLAG_PANNING;
                  break;
                case XM.VX_TONE_PORTAMENTO:
                  if (paramy) voice.portaSpeed = paramy << 4;
                  break;
              }
            }
          }

          if (row.effect == XM.FX_EXTENDED_EFFECTS && ((row.param >> 4) == XM.EX_NOTE_DELAY)) {
            voice.delay = voice.flags;
            voice.flags = 0;
            voice = voice.next;
            continue;
          }

          if (instrument.hasVolume)
            envelope(voice.volEnvelope, instrument.volData, XM.FLAG_VOLUME, voice);
          else if (voice.keyoff) {
            voice.volume = 0;
            voice.flags |= XM.FLAG_VOLUME;
          }

          if (instrument.hasPanning)
            envelope(voice.panEnvelope, instrument.panData, XM.FLAG_PANNING, voice);

          if (row.effect) {
            paramx = row.param >> 4;
            paramy = row.param & 15;

            switch (row.effect) {
              case XM.FX_PORTAMENTO_UP:
                if (row.param) voice.portaUp = row.param << 2;
                break;
              case XM.FX_PORTAMENTO_DOWN:
                if (row.param) voice.portaDown = row.param << 2;
                break;
              case XM.FX_TONE_PORTAMENTO:
                if (row.param) voice.portaSpeed = row.param;
                break;
              case XM.FX_VIBRATO:
                if (paramx) voice.vibratoSpeed = paramx;
                if (paramy) voice.vibratoDepth = paramy << 2;
                voice.vibratoOn = 1;
                break;
              case XM.FX_TONE_PORTAMENTO_VOLUME_SLIDE:
                if (row.param) voice.volSlide = row.param;
                break;
              case XM.FX_VIBRATO_VOLUME_SLIDE:
                if (row.param) voice.volSlide = row.param;
                voice.vibratoOn = 1;
                break;
              case XM.FX_TREMOLO:
                if (paramx) voice.tremoloSpeed = paramx;
                if (paramy) voice.tremoloDepth = paramy;
                break;
              case XM.FX_SET_PANNING:
                voice.panning = row.param;
                voice.flags |= XM.FLAG_PANNING;
                break;
              case XM.FX_SAMPLE_OFFSET:
                if (row.param) voice.sampleOffset = row.param << 8;
                if (voice.sampleOffset >= sample.length) {
                  voice.sampleOffset = 0;
                  voice.flags &= ~XM.FLAG_TRIGGER;
                  voice.flags |=  XM.FLAG_STOP;
                }
                break;
              case XM.FX_VOLUME_SLIDE:
                if (row.param) voice.volSlide = row.param;
                break;
              case XM.FX_POSITION_JUMP:
                nextOrder = row.param;
                nextPosition = 0;
                if (nextOrder >= length) mixer.complete = 1;
                jumpFlag = 1;
                break;
              case XM.FX_SET_VOLUME:
                voice.volume = row.param;
                voice.flags |= XM.FLAG_VOLUME;
                break;
              case XM.FX_PATTERN_BREAK:
                nextPosition = ((row.param * 10) + paramy) * channels;
                if (!jumpFlag) nextOrder = order + 1;
                break;
              case XM.FX_EXTENDED_EFFECTS:

                switch (paramx) {
                  case XM.EX_FINE_PORTAMENTO_UP:
                    if (paramy) voice.finePortaUp = paramy << 2;
                    voice.frequency -= voice.finePortaUp;
                    break;
                  case XM.EX_FINE_PORTAMENTO_DOWN:
                    if (paramy) voice.finePortaDown = paramy << 2;
                    voice.frequency += voice.finePortaDown;
                    break;
                  case XM.EX_VIBRATO_CONTROL:
                    voice.waveControl = (voice.waveControl & 0xf0) | paramy;
                    break;
                  case XM.EX_SET_FINETUNE:
                    voice.finetune = paramy;
                    voice.flags |= XM.FLAG_PERIOD;
                    break;
                  case XM.EX_PATTERN_LOOP:
                    if (!paramy) {
                      voice.patternLoopRow = position;
                    } else {
                      if (!voice.patternLoopCnt) {
                        voice.patternLoopCnt = paramy;
                      } else {
                        voice.patternLoopCnt--;
                      }

                      if (voice.patternLoopCnt)
                        nextPosition = voice.patternLoopRow;
                    }
                    break;
                  case XM.EX_TREMOLO_CONTROL:
                    voice.waveControl = (voice.waveControl & 0x0f) | (paramy << 4);
                    break;
                  case XM.EX_FINE_VOLUME_SLIDE_UP:
                    if (paramy) voice.fineVolSlideUp = paramy;
                    voice.volume += voice.fineVolSlideUp;
                    if (voice.volume > 64) voice.volume = 64;
                    voice.flags |= XM.FLAG_VOLUME;
                    break;
                  case XM.EX_FINE_VOLUME_SLIDE_DOWN:
                    if (paramy) voice.fineVolSlideDown = paramy;
                    voice.volume -= voice.fineVolSlideDown;
                    if (voice.volume < 0) voice.volume = 0;
                    voice.flags |= XM.FLAG_VOLUME;
                    break;
                  case XM.EX_PATTERN_DELAY:
                    patternDelay = paramy * speed;
                    break;
                }

                break;
              case XM.FX_SET_SPEED:
                if (row.param < 32) counter = row.param;
                  else mixer.samplesTick = 110250 / row.param;
                break;
              case XM.FX_SET_GLOBAL_VOLUME:
                master = row.param;
                if (master > 64) master = 64;
                voice.flags |= XM.FLAG_VOLUME;
                break;
              case XM.FX_GLOBAL_VOLUME_SLIDE:
                if (row.param) voice.volSlideMaster = row.param;
                break;
              case XM.FX_PANNING_SLIDE:
                if (row.param) voice.panSlide = row.param;
                break;
              case XM.FX_SET_ENVELOPE_POSITION:
                if (instrument.hasVolume) {
                  for (var i:int = 0; i < instrument.volData.total; ++i)
                    if (row.param < instrument.volData.points[i].frame) break;

                  voice.volEnvelope.position = i;
                  var diff:int = instrument.volData.total - 1;

                  if (i >= diff) {
                    voice.volEnvelope.value = instrument.volData.points[diff].value;
                    voice.volEnvelope.stopped = 1;
                  } else {
                    voice.volEnvelope.stopped = 0;
                    voice.volEnvelope.frame = row.param;
                    voice.volEnvelope.position++;

                    var curr:XMPoint = instrument.volData.points[i];
                    var next:XMPoint = instrument.volData.points[voice.volEnvelope.position];
                    diff = next.frame - curr.frame;

                    if (diff) voice.volEnvelope.delta = ((next.value - curr.value) << 16) / diff;
                      else voice.volEnvelope.delta = 0;

                    diff = voice.volEnvelope.frame - curr.frame;
                    voice.volEnvelope.fraction = (curr.value << 16) + (voice.volEnvelope.delta * diff);
                    voice.volEnvelope.value = voice.volEnvelope.fraction >> 16;
                  }
                }
                break;
              case XM.FX_MULTI_RETRIG_NOTE:
                if (paramx) voice.retrigX = paramx;
                if (paramy) voice.retrigY = paramy;
                if (!row.volume) {
                  if (voice.retrigY) {
                    var t:int = timer;
                    if (!row.volume) t++;
                    if ((t % voice.retrigY) == 0) {
                      if ((!row.volume || row.volume > 80) && voice.retrigX) {
                        switch (voice.retrigX) {
                          case 1:
                            voice.volume--;
                            break;
                          case 2:
                            voice.volume -= 2;
                            break;
                          case 3:
                            voice.volume -= 4;
                            break;
                          case 4:
                            voice.volume -= 8;
                            break;
                          case 5:
                            voice.volume -= 16;
                            break;
                          case 6:
                            voice.volume = (voice.volume << 1) / 3;
                            break;
                          case 7:
                            voice.volume >>= 1;
                            break;
                          case 9:
                            voice.volume++;
                            break;
                          case 10:
                            voice.volume += 2;
                            break;
                          case 11:
                            voice.volume += 4;
                            break;
                          case 12:
                            voice.volume += 8;
                            break;
                          case 13:
                            voice.volume += 16;
                          case 14:
                            voice.volume = (voice.volume * 3) >> 1;
                            break;
                          case 15:
                            voice.volume <<= 1;
                            break;
                        }

                        if (voice.volume > 64) voice.volume = 64;
                          else if (voice.volume < 0) voice.volume = 0;
                      }
                    }
                  }
                }
                break;
              case XM.FX_TREMOR:
                if (row.param) {
                  voice.tremorOn  = ++paramx;
                  voice.tremorOff = ++paramy + paramx;
                }
                break;
              case XM.FX_EXTRA_FINE_PORTAMENTO:
                if (paramx == 1) {
                  if (paramy) voice.xtraPortaUp = paramy << 2;
                  voice.frequency -= voice.xtraPortaUp;
                } else if (paramx == 2) {
                  if (paramy) voice.xtraPortaDown = paramy << 2;
                  voice.frequency += voice.xtraPortaDown;
                }
                break;
            }
          }

          if (instrument.vibratoSpeed) voice.autoVibrato();
          update(voice);
          voice = voice.next;
        }
      } else {
        effects();
      }

      if (++timer >= (counter + patternDelay)) {
        patternDelay = timer = 0;

        if (nextPosition < 0) {
          nextPosition = position + channels;

          if (nextPosition >= pattern.size) {
            nextOrder = order + 1;
            nextPosition = 0;

            if (nextOrder >= length) {
              nextOrder = restart;
              mixer.complete = 1;
            }
          }
        }
      }
    }

    override protected function initialize():void {
      var i:int, voice:XMVoice;
      super.initialize();

      order        =  0;
      position     =  0;
      nextOrder    = -1;
      nextPosition = -1;
      patternDelay =  0;

      voices = new Vector.<XMVoice>(channels, true);

      for (i = 0; i < channels; ++i) {
        voice = new XMVoice(i);
        voice.instrument = instruments[0];
        voice.sample = voice.instrument.samples[0];
        voice.channel = mixer.channels[i];
        voice.channel.sample = voice.sample;
        voice.channel.pointer = 0;
        voice.channel.counter = voice.sample.length;
        voices[i] = voice;
        if (i) voices[int(i - 1)].next = voice;
      }
    }

    private function effects():void {
      var instrument:XMInstrument, paramx:int, paramy:int, row:XMRow, sample:XMSample, slide:int, voice:XMVoice;
      voice = voices[0];

      while (voice) {
        row = pattern.rows[int(position + voice.index)];
        instrument = voice.instrument;
        sample = instrument.samples[instrument.noteSamples[voice.note]];
        voice.flags = 0;

        if (voice.delay) {
          if ((row.param & 15) == timer) {
            voice.flags = voice.delay;
            voice.delay = 0;
          } else {
            voice = voice.next;
            continue;
          }
        }

        if (row.effect == XM.FX_KEYOFF) {
          if (timer == row.param) {
            voice.keyoff = 1;
            voice.isFading = 1;
          }
        }

        if (instrument.hasVolume)
          envelope(voice.volEnvelope, instrument.volData, XM.FLAG_VOLUME, voice);
        else if (voice.keyoff) {
          voice.volume = 0;
          voice.flags |= XM.FLAG_VOLUME;
        }

        if (instrument.hasPanning)
          envelope(voice.panEnvelope, instrument.panData, XM.FLAG_PANNING, voice);

        if (row.volume) {
          paramx = row.volume >> 4;
          paramy = row.volume & 15;

          switch (paramx) {
            case XM.VX_VOLUME_SLIDE_DOWN:
              voice.volume -= paramy;
              if (voice.volume < 0) voice.volume = 0;
              voice.flags |= XM.FLAG_VOLUME;
              break;
            case XM.VX_VOLUME_SLIDE_UP:
              voice.volume += paramy;
              if (voice.volume > 64) voice.volume = 64;
              voice.flags |= XM.FLAG_VOLUME;
              break;
            case XM.VX_VIBRATO:
              voice.vibrato();
              break;
            case XM.VX_PANNING_SLIDE_LEFT:
              voice.panning -= paramy;
              voice.flags |= XM.FLAG_PANNING;
              break;
            case XM.VX_PANNING_SLIDE_RIGHT:
              voice.panning += paramy;
              voice.flags |= XM.FLAG_PANNING;
              break;
            case XM.VX_TONE_PORTAMENTO:
              voice.tonePortamento();
              break;
          }
        }

        paramx = row.param >> 4;
        paramy = row.param & 15;

        switch (row.effect) {
          case XM.FX_ARPEGGIO:
            if (!row.param) break;
            voice.frequency = voice.period;
            var r:int = (timer - counter) % 3;
            if (r < 0) r += 3;
            switch (r) {
              case 1:
                voice.frequency -= (paramy << 6);
                break;
              case 2:
                voice.frequency -= (paramx << 6);
                break;
            }
            voice.arpeggioOn = 1;
            voice.flags |= XM.FLAG_PERIOD;
            break;
          case XM.FX_PORTAMENTO_UP:
            voice.frequency = voice.period - voice.portaUp;
            if (voice.frequency < 0) voice.frequency = 1;
            voice.period = voice.frequency;
            voice.flags |= XM.FLAG_PERIOD;
            break;
          case XM.FX_PORTAMENTO_DOWN:
            voice.frequency = voice.period + voice.portaDown;
            voice.period = voice.frequency;
            voice.flags |= XM.FLAG_PERIOD;
            break;
          case XM.FX_TONE_PORTAMENTO:
            voice.tonePortamento();
            break;
          case XM.FX_VIBRATO:
            voice.vibrato();
            break;
          case XM.FX_TONE_PORTAMENTO_VOLUME_SLIDE:
            voice.tonePortamento();
            slide = 1;
            break;
          case XM.FX_VIBRATO_VOLUME_SLIDE:
            voice.vibrato();
            slide = 1;
            break;
          case XM.FX_TREMOLO:
            voice.tremolo();
            break;
          case XM.FX_VOLUME_SLIDE:
            slide = 1;
            break;
          case XM.FX_EXTENDED_EFFECTS:

            switch (paramx) {
              case XM.EX_NOTE_CUT:
                if (timer == paramy) {
                  voice.volume = 0;
                  voice.flags |= XM.FLAG_VOLUME;
                }
                break;
              case XM.EX_RETRIG_NOTE:
                if ((timer % paramy) == 0) {
                  voice.volEnvelope.reset(64);
                  voice.panEnvelope.reset(32);
                  voice.flags |= (XM.FLAG_VOLUME | XM.FLAG_PANNING | XM.FLAG_TRIGGER);
                }
                break;
            }

            break;
          case XM.FX_GLOBAL_VOLUME_SLIDE:
            paramx = voice.volSlideMaster >> 4;
            paramy = voice.volSlideMaster & 15;

            if (paramx) {
              master += paramx;
              if (master > 64) master = 64;
            } else if (paramy) {
              master -= paramy;
              if (master < 0) master = 0;
            }

            voice.flags |= XM.FLAG_VOLUME;
            break;
          case XM.FX_PANNING_SLIDE:
            paramx = voice.panSlide >> 4;
            paramy = voice.panSlide & 15;

            if (paramx) {
              voice.panning += paramx;
              if (voice.panning > 255) voice.panning = 255;
            } else if (paramy) {
              voice.panning -= paramy;
              if (voice.panning < 0) voice.panning = 0;
            }

            voice.flags |= XM.FLAG_PANNING;
            break;
          case XM.FX_MULTI_RETRIG_NOTE:
            var t:int = timer;
            if (!row.volume) t++;
            if ((t % voice.retrigY) == 0) {
              if ((!row.volume || row.volume > 80) && voice.retrigX) {
                switch (voice.retrigX) {
                  case 1:
                    voice.volume--;
                    break;
                  case 2:
                    voice.volume -= 2;
                    break;
                  case 3:
                    voice.volume -= 4;
                    break;
                  case 4:
                    voice.volume -= 8;
                    break;
                  case 5:
                    voice.volume -= 16;
                    break;
                  case 6:
                    voice.volume = (voice.volume << 1) / 3;
                    break;
                  case 7:
                    voice.volume >>= 1;
                    break;
                  case 9:
                    voice.volume++;
                    break;
                  case 10:
                    voice.volume += 2;
                    break;
                  case 11:
                    voice.volume += 4;
                    break;
                  case 12:
                    voice.volume += 8;
                    break;
                  case 13:
                    voice.volume += 16;
                  case 14:
                    voice.volume = (voice.volume * 3) >> 1;
                    break;
                  case 15:
                    voice.volume <<= 1;
                    break;
                }

                if (voice.volume > 64) voice.volume = 64;
                  else if (voice.volume < 0) voice.volume = 0;
                voice.flags |= XM.FLAG_VOLUME;
              }
              voice.flags |= XM.FLAG_TRIGGER;
            }
            break;
          case XM.FX_TREMOR:
            voice.tremor();
            break;
        }

        if (slide) {
          paramx = voice.volSlide >> 4;
          paramy = voice.volSlide & 15;

          if (paramx) {
            voice.volume += paramx;
            if (voice.volume > 64) voice.volume = 64;
          } else if (paramy) {
            voice.volume -= paramy;
            if (voice.volume < 0) voice.volume = 0;
          }

          slide = 0;
          voice.flags |= XM.FLAG_VOLUME;
        }

        if (instrument.vibratoSpeed) voice.autoVibrato();
        update(voice);
        voice = voice.next;
      }
    }

    private function update(voice:XMVoice):void {
      var chan:SBChannel, flags:int, value:Number;
      chan = voice.channel;
      flags = voice.flags;
      voice.flags = 0;

      if (flags & XM.FLAG_VOLUME) {
        if (voice.volume < 0) voice.volume = 0;
          else if (voice.volume > 64) voice.volume = 64;

        value  = (voice.volEnvelope.value * voice.volume * voice.fadeout * master);
        value *= (1.0 / (64 * 64 * 65536 * 64)) * 0.5;

        chan.volume = value;
        chan.lvol = (value * (256 - chan.panning)) / 256;
        chan.rvol = (value * chan.panning) / 256;
      }

      if (flags & XM.FLAG_PANNING) {
        value = voice.panning + ((voice.panEnvelope.value - 32) * ((128 - Math.abs(voice.panning - 128)) / 32));
        if (value < 0) value = 0;
          else if (value > 255) value = 255;

        chan.panning = value;
        chan.lvol = (chan.volume * (256 - value)) / 256;
        chan.rvol = (chan.volume * value) / 256;
      }

      if (flags & XM.FLAG_TRIGGER) {
        chan.sample  = voice.sample;
        chan.pointer = voice.sampleOffset;
        chan.counter = voice.sample.length;

        if (chan.speed < 0) chan.speed = -chan.speed;
        voice.sampleOffset = 0;
      }

      if (flags & XM.FLAG_PERIOD) {
        value = int((548077568 * Math.pow(2, ((4608 - (voice.frequency + voice.frqDelta)) / 768))) / 44100) / 65536;

        if (chan.speed < 0) chan.speed = -value;
          else chan.speed = value;

        if (voice.frequency > 9212) chan.speed = 0;
        voice.frqDelta = 0;
      }

      if (flags & XM.FLAG_STOP) chan.sample = null;
    }

    private function envelope(envelope:XMEnvelope, data:XMData, flag:int, voice:XMVoice):void {
      var curr:XMPoint, currPos:int, diff:int, next:XMPoint, nextPos:int;

      if (voice.isFading) {
        voice.fadeout -= (voice.instrument.fadeout << 1);

        if (voice.fadeout < 0) {
          voice.fadeout = 0;
          voice.isFading = 0;
        }
      }

      if (!envelope.stopped) {
        currPos = envelope.position;
        curr = data.points[currPos];
    
        if (envelope.frame == curr.frame) {
          if ((data.flags & XM.ENVELOPE_LOOP) && currPos == data.loopEnd) {
            currPos = envelope.position = data.loopStart;
            curr = data.points[currPos];
            envelope.frame = curr.frame;
          }
      
          if (currPos == (data.total - 1)) {
            envelope.value = curr.value;
            envelope.stopped = 1;
            voice.flags |= flag;
            return;
          }
      
          nextPos = currPos + 1;
          next = data.points[nextPos];
      
          if ((data.flags & XM.ENVELOPE_SUSTAIN) && currPos == data.sustain && !voice.keyoff) {
            envelope.value = curr.value;
            voice.flags |= flag;
            return;
          }
      
          diff = next.frame - curr.frame;
      
          if (diff) envelope.delta = ((next.value - curr.value) << 16) / diff;
            else envelope.delta = 0.0;
      
          envelope.fraction = (curr.value << 16);
          envelope.position++;
        } else {
          envelope.fraction += envelope.delta;
        }

        envelope.value = (envelope.fraction >> 16);
        envelope.frame++;
      }
      voice.flags |= flag;
    }
  }
}