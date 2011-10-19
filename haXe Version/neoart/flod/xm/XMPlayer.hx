/* FlodXM Alpha 3
   2011/09/17
   Christian Corti
   Neoart Costa Rica

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 	 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 	 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 	 IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package neoart.flod.xm;

import flash.utils.ByteArray;
import neoart.flod.core.SBPlayer;
import neoart.flod.core.Soundblaster;
import neoart.flod.core.SBChannel;
import flash.Vector;

@final class XMPlayer extends SBPlayer 
{
  public var patterns     : Vector<XMPattern>;
  public var instruments  : Vector<XMInstrument>;
  public var amiga        : Int;

  public var voices       : Vector<XMVoice>;
  public var order        : Int;
  public var position     : Int;
  public var nextOrder    : Int;
  public var nextPosition : Int;
  public var pattern      : XMPattern;
  public var patternDelay : Int;
  public var tickTemp     : Int;

  public function new(mixer:Soundblaster = null) 
  {
    super(mixer);
  }

  override public function load(stream : ByteArray) : Int 
  {
    super.load(stream);
    XMLoader.load(stream, mixer);
    if (version != 0) setup();
    return version;
  }

  override public function process() : Void 
  {
    var instrument:XMInstrument;
    var isPorta : Bool;
    var jumpFlag : Int = 0;
    var paramx : Int;
    var paramy : Int;
    var row:XMRow;
    var sample:XMSample;
    var voice:XMVoice;

    if (timer == 0) {
      if (nextOrder >= 0) order = nextOrder;
      if (nextPosition >= 0) position = nextPosition;
      nextOrder = nextPosition = -1;

      pattern = patterns[track[order]];
      voice = voices[0];

      while (voice != null) {
        row = pattern.rows[Std.int(position + voice.index)];

        if (voice.arpeggioOn != 0) {
          voice.arpeggioOn = 0;
          voice.frequency = voice.period;
          voice.flags = XM.FLAG_PERIOD;
        } else if (voice.vibratoOn != 0) {
          if (row.effect != XM.FX_VIBRATO && row.effect != XM.FX_VIBRATO_VOLUME_SLIDE) {
            voice.frequency = voice.period;
            voice.flags = XM.FLAG_PERIOD;
          } else voice.vibratoOn = 0;
        }

        paramx = row.volume >> 4;
        
        // TODO: bool to int ???
        isPorta = (row.effect == XM.FX_TONE_PORTAMENTO || row.effect == XM.FX_TONE_PORTAMENTO_VOLUME_SLIDE || paramx == XM.VX_TONE_PORTAMENTO);

        if (row.note == XM.NOTE_KEYOFF || (row.effect == XM.FX_KEYOFF && row.param == 0)) {
          voice.keyoff = 1;
          voice.isFading = 1;
        } else {
          voice.keyoff = 0;
        }

        //if (row.note && !voice.keyoff) {
        if (row.note != 0 && voice.keyoff == 0) {
          if (!isPorta) {
            voice.note = row.note - 1;
            voice.flags |= XM.FLAG_PERIOD | XM.FLAG_TRIGGER;
          }
        }

        if (row.instrument != 0) {
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

        //CHECK: if (row.note && !voice.keyoff) {
        if (row.note != 0 && voice.keyoff == 0) {
          var value : Int = ((120 - (row.note + sample.relative - 1)) << 6) - ((voice.finetune >> 3) << 2);
          if (!isPorta) voice.frequency = voice.period = value;
            else voice.portaPeriod = value;
        }

        if (row.volume != 0) {
          if (row.volume >= 16 && row.volume <= 80) {
            voice.volume = row.volume - 16;
            voice.flags |= XM.FLAG_VOLUME;
          } else {
            paramy = row.volume & 15;

            switch (paramx) 
            {
              case XM.VX_FINE_VOLUME_SLIDE_DOWN:
              {
                voice.volume -= paramy;
                if (voice.volume < 0) voice.volume = 0;
                voice.flags |= XM.FLAG_VOLUME;
              }
              case XM.VX_FINE_VOLUME_SLIDE_UP:
              {
                voice.volume += paramy;
                if (voice.volume > 64) voice.volume = 64;
                voice.flags |= XM.FLAG_VOLUME;
              }
              case XM.VX_SET_VIBRATO_SPEED:
              {
                if (paramy != 0) voice.vibratoSpeed = paramy;
              }
              case XM.VX_VIBRATO:
              {
                if (paramy != 0) voice.vibratoDepth = paramy << 2;
              }
              case XM.VX_SET_PANNING:
              {
                voice.panning = paramy << 4;
                voice.flags |= XM.FLAG_PANNING;
              }
              case XM.VX_TONE_PORTAMENTO:
              {
                if (paramy != 0) voice.portaSpeed = paramy << 4;
              }
            }
          }
        }

        if (row.effect == XM.FX_EXTENDED_EFFECTS && ((row.param >> 4) == XM.EX_NOTE_DELAY)) {
          voice.delay = voice.flags;
          voice.flags = 0;
          voice = voice.next;
          continue;
        }

        if (instrument.hasVolume != 0)
          envelope(voice.volEnvelope, instrument.volData, XM.FLAG_VOLUME, voice);
        else if (voice.keyoff != 0) {
          voice.volume = 0;
          voice.flags |= XM.FLAG_VOLUME;
        }

        if (instrument.hasPanning != 0)
          envelope(voice.panEnvelope, instrument.panData, XM.FLAG_PANNING, voice);

        if (row.effect != 0) {
          paramx = row.param >> 4;
          paramy = row.param & 15;

          switch (row.effect) 
          {
            case XM.FX_PORTAMENTO_UP:
            {
              if (row.param != 0) voice.portaUp = row.param << 2;
            }
            case XM.FX_PORTAMENTO_DOWN:
            {
              if (row.param != 0) voice.portaDown = row.param << 2;
            }
            case XM.FX_TONE_PORTAMENTO:
            {
              if (row.param != 0) voice.portaSpeed = row.param;
            }
            case XM.FX_VIBRATO:
            {
              if (paramx != 0) voice.vibratoSpeed = paramx;
              if (paramy != 0) voice.vibratoDepth = paramy << 2;
              voice.vibratoOn = 1;
            }
            case XM.FX_TONE_PORTAMENTO_VOLUME_SLIDE:
            {
              if (row.param != 0) voice.volSlide = row.param;
            }
            case XM.FX_VIBRATO_VOLUME_SLIDE:
            {
              if (row.param != 0) voice.volSlide = row.param;
              voice.vibratoOn = 1;
            }
            case XM.FX_TREMOLO:
            {
              if (paramx != 0) voice.tremoloSpeed = paramx;
              if (paramy != 0) voice.tremoloDepth = paramy;
            }
            case XM.FX_SET_PANNING:
            {
              voice.panning = row.param;
              voice.flags |= XM.FLAG_PANNING;
            }
            case XM.FX_SAMPLE_OFFSET:
            {
              if (row.param != 0) voice.sampleOffset = row.param << 8;
              if (voice.sampleOffset >= sample.length) {
                voice.sampleOffset = 0;
                voice.flags &= ~XM.FLAG_TRIGGER;
                voice.flags |=  XM.FLAG_STOP;
              }
            }
            case XM.FX_VOLUME_SLIDE:
            {
              if (row.param != 0) voice.volSlide = row.param;
            }
            case XM.FX_POSITION_JUMP:
            {
              nextOrder = row.param;
              nextPosition = 0;
              if (nextOrder >= length) mixer.completed = 1;
              jumpFlag = 1;
            }
            case XM.FX_SET_VOLUME:
            {
              voice.volume = row.param;
              voice.flags |= XM.FLAG_VOLUME;
            }
            case XM.FX_PATTERN_BREAK:
            {
              nextPosition = ((row.param * 10) + paramy) * channels;
              if (jumpFlag == 0) nextOrder = order + 1;
            }
            case XM.FX_EXTENDED_EFFECTS:
            {
              switch (paramx) 
              {
                case XM.EX_FINE_PORTAMENTO_UP:
                {
                  if (paramy != 0) voice.finePortaUp = paramy << 2;
                  voice.frequency -= voice.finePortaUp;
                }
                case XM.EX_FINE_PORTAMENTO_DOWN:
                {
                  if (paramy != 0) voice.finePortaDown = paramy << 2;
                  voice.frequency += voice.finePortaDown;
                }
                case XM.EX_VIBRATO_CONTROL:
                {
                  voice.waveControl = (voice.waveControl & 0xf0) | paramy;
                }
                case XM.EX_SET_FINETUNE:
                {
                  voice.finetune = paramy;
                  voice.flags |= XM.FLAG_PERIOD;
                }
                case XM.EX_PATTERN_LOOP:
                {
                  if (paramy == 0) {
                    voice.patternLoopRow = position;
                  } else {
                    if (voice.patternLoopCnt == 0) {
                      voice.patternLoopCnt = paramy;
                    } else {
                      voice.patternLoopCnt--;
                    }

                    if (voice.patternLoopCnt != 0)
                      nextPosition = voice.patternLoopRow;
                  }
                }
                case XM.EX_TREMOLO_CONTROL:
                {
                  voice.waveControl = (voice.waveControl & 0x0f) | (paramy << 4);
                }
                case XM.EX_FINE_VOLUME_SLIDE_UP:
                {
                  if (paramy != 0) voice.fineVolSlideUp = paramy;
                  voice.volume += voice.fineVolSlideUp;
                  if (voice.volume > 64) voice.volume = 64;
                  voice.flags |= XM.FLAG_VOLUME;
                }
                case XM.EX_FINE_VOLUME_SLIDE_DOWN:
                {
                  if (paramy != 0) voice.fineVolSlideDown = paramy;
                  voice.volume -= voice.fineVolSlideDown;
                  if (voice.volume < 0) voice.volume = 0;
                  voice.flags |= XM.FLAG_VOLUME;
                }
                case XM.EX_PATTERN_DELAY:
                {
                  patternDelay = paramy * speed;
                }
              }
            }
            case XM.FX_SET_SPEED:
            {
              if (row.param < 32) 
              {
                counter = row.param;
              }
              else 
              {
                mixer.samplesTick = Std.int(110250 / row.param);
              }
            }
            case XM.FX_SET_GLOBAL_VOLUME:
            {
              master = row.param;
              if (master > 64) master = 64;
              voice.flags |= XM.FLAG_VOLUME;
            }
            case XM.FX_GLOBAL_VOLUME_SLIDE:
            {
              if (row.param != 0) voice.volSlideMaster = row.param;
            }
            case XM.FX_PANNING_SLIDE:
            {
              if (row.param != 0) voice.panSlide = row.param;
            }
            case XM.FX_SET_ENVELOPE_POSITION:
            {
              if (instrument.hasVolume != 0) 
              {
                var i : Int = 0;
                
                // TODO: check if the i is available outside the loop?
                /*
                for (i in 0...instrument.volData.total)
                  if (row.param < instrument.volData.points[i].frame) break;
                */
                while(i < instrument.volData.total)
                {
                  if (row.param < instrument.volData.points[i].frame) break;
                  i++;
                }

                voice.volEnvelope.position = i;
                var diff : Int = instrument.volData.total - 1;

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

                  if (diff != 0) voice.volEnvelope.delta = Std.int(((next.value - curr.value) << 16) / diff);
                    else voice.volEnvelope.delta = 0;

                  diff = voice.volEnvelope.frame - curr.frame;
                  voice.volEnvelope.fraction = (curr.value << 16) + (voice.volEnvelope.delta * diff);
                  voice.volEnvelope.value = voice.volEnvelope.fraction >> 16;
                }
              }
            }
            case XM.FX_MULTI_RETRIG_NOTE:
            {
              if (paramx != 0) voice.retrigX = paramx;
              if (paramy != 0) voice.retrigY = paramy;
              if (row.volume == 0) {
                if (voice.retrigY != 0) {
                  var t : Int = timer;
                  if (row.volume == 0) t++;
                  if ((t % voice.retrigY) == 0) {
                    //if ((!row.volume || row.volume > 80) && voice.retrigX) {
                    if ((row.volume == 0 || row.volume > 80) && voice.retrigX != 0) {
                      switch (voice.retrigX) {
                        case 1:
                          voice.volume--;
                        case 2:
                          voice.volume -= 2;
                        case 3:
                          voice.volume -= 4;
                        case 4:
                          voice.volume -= 8;
                        case 5:
                          voice.volume -= 16;
                        case 6:
                          voice.volume = Std.int((voice.volume << 1) / 3);
                        case 7:
                          voice.volume >>= 1;
                        case 9:
                          voice.volume++;
                        case 10:
                          voice.volume += 2;
                        case 11:
                          voice.volume += 4;
                        case 12:
                          voice.volume += 8;
                        
                        // TODO: shouldn't 13 have a break after?
                        // I'm putting it in and check with the original programmer
                        case 13:
                          voice.volume += 16;
                        case 14:
                          voice.volume = (voice.volume * 3) >> 1;                        
                        case 15:
                          voice.volume <<= 1;
                      }

                      if (voice.volume > 64) voice.volume = 64;
                        else if (voice.volume < 0) voice.volume = 0;
                    }
                  }
                }
              }
            }
            case XM.FX_TREMOR:
            {
              if (row.param != 0) {
                voice.tremorOn  = ++paramx;
                voice.tremorOff = ++paramy + paramx;
              }
            }
            case XM.FX_EXTRA_FINE_PORTAMENTO:
            {
              if (paramx == 1) {
                if (paramy != 0) voice.xtraPortaUp = paramy << 2;
                voice.frequency -= voice.xtraPortaUp;
              } else if (paramx == 2) {
                if (paramy != 0) voice.xtraPortaDown = paramy << 2;
                voice.frequency += voice.xtraPortaDown;
              }
            }
          }
        }

        if (instrument.vibratoSpeed != 0) voice.autoVibrato();
        update(voice);
        voice = voice.next;
      }
    } else {
      effects();
    }

    if (++timer >= (counter + patternDelay)) 
    {
      patternDelay = timer = 0;

      if (nextPosition < 0) 
      {
        nextPosition = position + channels;

        if (nextPosition >= pattern.size) 
        {
          nextOrder = order + 1;
          nextPosition = 0;

          if (nextOrder >= length) 
          {
            trace("completed!");
            
            nextOrder = restart;
            mixer.completed = 1;
          }
        }
      }
    }
  }

  override private function initialize() : Void 
  {
    //var i : Int;
    var voice:XMVoice;

    super.initialize();

    order        =  0;
    position     =  0;
    nextOrder    = -1;
    nextPosition = -1;
    patternDelay =  0;

    voices = new Vector<XMVoice>(channels, true);

    for (i in 0...channels) 
    {
      voice = new XMVoice(i);
      voice.instrument = instruments[0];
      voice.sample = voice.instrument.samples[0];
      voice.channel = mixer.channels[i];
      voice.channel.sample = voice.sample;
      voice.channel.pointer = 0;
      voice.channel.counter = voice.sample.length;
      voices[i] = voice;

      // if (i) :)
      if (i > 0) voices[Std.int(i - 1)].next = voice;
    }
  }

  private function effects() : Void 
  {
    var instrument:XMInstrument;
    var paramx : Int;
    var paramy : Int;
    var row:XMRow;
    var sample:XMSample;
    var slide : Int = 0;
    var voice:XMVoice;

    voice = voices[0];

    while (voice != null) 
    {
      row = pattern.rows[Std.int(position + voice.index)];
      instrument = voice.instrument;
      sample = instrument.samples[instrument.noteSamples[voice.note]];
      voice.flags = 0;

      if (voice.delay != 0) {
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

      if (instrument.hasVolume != 0)
        envelope(voice.volEnvelope, instrument.volData, XM.FLAG_VOLUME, voice);
      else if (voice.keyoff != 0) {
        voice.volume = 0;
        voice.flags |= XM.FLAG_VOLUME;
      }

      if (instrument.hasPanning != 0)
        envelope(voice.panEnvelope, instrument.panData, XM.FLAG_PANNING, voice);

      if (row.volume != 0) {
        paramx = row.volume >> 4;
        paramy = row.volume & 15;

        switch (paramx) 
        {
          case XM.VX_VOLUME_SLIDE_DOWN:
          {
            voice.volume -= paramy;
            if (voice.volume < 0) voice.volume = 0;
            voice.flags |= XM.FLAG_VOLUME;
          }
          case XM.VX_VOLUME_SLIDE_UP:
          {
            voice.volume += paramy;
            if (voice.volume > 64) voice.volume = 64;
            voice.flags |= XM.FLAG_VOLUME;
          }
          case XM.VX_VIBRATO:
          {
            voice.vibrato();
          }
          case XM.VX_PANNING_SLIDE_LEFT:
          {
            voice.panning -= paramy;
            voice.flags |= XM.FLAG_PANNING;
          }
          case XM.VX_PANNING_SLIDE_RIGHT:
          {
            voice.panning += paramy;
            voice.flags |= XM.FLAG_PANNING;
          }
          case XM.VX_TONE_PORTAMENTO:
          {
            voice.tonePortamento();
          }
        }
      }

      paramx = row.param >> 4;
      paramy = row.param & 15;

      switch (row.effect) 
      {
        case XM.FX_ARPEGGIO:
        {
          // original code
          // if (!row.param) break;
          if (row.param != 0)
          {
            voice.frequency = voice.period;
            var r : Int = (timer - counter) % 3;
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
          }
        }
        case XM.FX_PORTAMENTO_UP:
        {
          voice.frequency = voice.period - voice.portaUp;
          if (voice.frequency < 0) voice.frequency = 1;
          voice.period = voice.frequency;
          voice.flags |= XM.FLAG_PERIOD;
        }
        case XM.FX_PORTAMENTO_DOWN:
        {
          voice.frequency = voice.period + voice.portaDown;
          voice.period = voice.frequency;
          voice.flags |= XM.FLAG_PERIOD;
        }
        case XM.FX_TONE_PORTAMENTO:
        {
          voice.tonePortamento();
        }
        case XM.FX_VIBRATO:
        {
          voice.vibrato();
        }
        case XM.FX_TONE_PORTAMENTO_VOLUME_SLIDE:
        {
          voice.tonePortamento();
          slide = 1;
        }
        case XM.FX_VIBRATO_VOLUME_SLIDE:
        {
          voice.vibrato();
          slide = 1;
        }
        case XM.FX_TREMOLO:
        {
          voice.tremolo();
        }
        case XM.FX_VOLUME_SLIDE:
        {
          slide = 1;
        }
        case XM.FX_EXTENDED_EFFECTS:
        {
          switch (paramx) {
            case XM.EX_NOTE_CUT:
            {
              if (timer == paramy) 
              {
                voice.volume = 0;
                voice.flags |= XM.FLAG_VOLUME;
              }
            }
            case XM.EX_RETRIG_NOTE:
            {
              if ((timer % paramy) == 0) 
              {
                voice.volEnvelope.reset(64);
                voice.panEnvelope.reset(32);
                voice.flags |= (XM.FLAG_VOLUME | XM.FLAG_PANNING | XM.FLAG_TRIGGER);
              }
            }
          }
        }
        case XM.FX_GLOBAL_VOLUME_SLIDE:
        {
          paramx = voice.volSlideMaster >> 4;
          paramy = voice.volSlideMaster & 15;

          if (paramx != 0) {
            master += paramx;
            if (master > 64) master = 64;
          } else if (paramy != 0) {
            master -= paramy;
            if (master < 0) master = 0;
          }

          voice.flags |= XM.FLAG_VOLUME;
        }
        case XM.FX_PANNING_SLIDE:
        {
          paramx = voice.panSlide >> 4;
          paramy = voice.panSlide & 15;

          if (paramx != 0) {
            voice.panning += paramx;
            if (voice.panning > 255) voice.panning = 255;
          } else if (paramy != 0) {
            voice.panning -= paramy;
            if (voice.panning < 0) voice.panning = 0;
          }

          voice.flags |= XM.FLAG_PANNING;
        }
        case XM.FX_MULTI_RETRIG_NOTE:
        {
          var t : Int = timer;
          if (row.volume == 0) t++;
          if ((t % voice.retrigY) == 0) {
            // CHECK: if ((!row.volume || row.volume > 80) && voice.retrigX) {
            if ((row.volume == 0 || row.volume > 80) && voice.retrigX != 0) {
              switch (voice.retrigX) 
              {
                case 1:
                  voice.volume--;
                case 2:
                  voice.volume -= 2;
                case 3:
                  voice.volume -= 4;
                case 4:
                  voice.volume -= 8;
                case 5:
                  voice.volume -= 16;
                case 6:
                  voice.volume = Std.int((voice.volume << 1) / 3);
                case 7:
                  voice.volume >>= 1;
                case 9:
                  voice.volume++;
                case 10:
                  voice.volume += 2;
                case 11:
                  voice.volume += 4;
                case 12:
                  voice.volume += 8;
                
                // original code
                /*
                case 13:
                  voice.volume += 16;
                case 14:
                  voice.volume = (voice.volume * 3) >> 1;
                  break;
                */
                case 13:
                  voice.volume += 16;
                case 14:
                  voice.volume = (voice.volume * 3) >> 1;

                case 15:
                  voice.volume <<= 1;
              }

              if (voice.volume > 64) voice.volume = 64;
                else if (voice.volume < 0) voice.volume = 0;
              voice.flags |= XM.FLAG_VOLUME;
            }
            voice.flags |= XM.FLAG_TRIGGER;
          }
        }
        case XM.FX_TREMOR:
        {
          voice.tremor();
        }
      }

      if (slide != 0) {
        paramx = voice.volSlide >> 4;
        paramy = voice.volSlide & 15;

        if (paramx != 0) {
          voice.volume += paramx;
          if (voice.volume > 64) voice.volume = 64;
        } else if (paramy != 0) {
          voice.volume -= paramy;
          if (voice.volume < 0) voice.volume = 0;
        }

        slide = 0;
        voice.flags |= XM.FLAG_VOLUME;
      }

      if (instrument.vibratoSpeed != 0) voice.autoVibrato();
      update(voice);
      voice = voice.next;
    }
  }

  private function update(voice:XMVoice) : Void {
    var chan:SBChannel;
    var flags : Int;
    var value : Float;

    chan = voice.channel;
    flags = voice.flags;
    voice.flags = 0;

    if ((flags & XM.FLAG_VOLUME) != 0) {
      if (voice.volume < 0) voice.volume = 0;
        else if (voice.volume > 64) voice.volume = 64;

      //value  = (voice.volEnvelope.value * voice.volume * voice.fadeout * master);
      //value *= (1.0 / (64.0 * 64.0 * 65536.0 * 64.0)) * 0.5;

      value  = (voice.volEnvelope.value / 64) * (voice.volume / 64) * (voice.fadeout / 65536) * (master / 64) * 0.5;

      chan.volume = value;
      chan.lvol = (value * (256 - chan.panning)) / 256;
      chan.rvol = (value * chan.panning) / 256;

      //trace(chan.volume);
      //trace(chan.lvol + "/" + chan.rvol);
    }

    if ((flags & XM.FLAG_PANNING) != 0) {
      
      value = voice.panning + ((voice.panEnvelope.value - 32) * ((128 - Math.abs(voice.panning - 128)) / 32));

      if (value < 0) value = 0;
        else if (value > 255) value = 255;

      chan.panning = value;
      chan.lvol = (chan.volume * (256 - value)) / 256;
      chan.rvol = (chan.volume * value) / 256;

      //trace("FLAG_PANNING " + chan.volume);
    }

    if ((flags & XM.FLAG_TRIGGER) != 0) {
      chan.sample  = voice.sample;
      chan.pointer = voice.sampleOffset;
      chan.counter = voice.sample.length;

      if (chan.speed < 0) chan.speed = -chan.speed;
      voice.sampleOffset = 0;

      //trace("FLAG_TRIGGER " + chan.speed);
    }

    if ((flags & XM.FLAG_PERIOD) != 0) {
      //trace("FLAG_PERIOD");
      // original code
      //value = int((548077568 * Math.pow(2, ((4608 - (voice.frequency + voice.frqDelta)) / 768))) / 44100) / 65536;

      value = Std.int((548077568.0 * Math.pow(2, ((4608.0 - (voice.frequency + voice.frqDelta)) / 768.0))) / 44100.0) / 65536.0;

      if (chan.speed < 0) chan.speed = -value;
        else chan.speed = value;

      if (voice.frequency > 9212) chan.speed = 0;
      voice.frqDelta = 0;
    }

    if ((flags & XM.FLAG_STOP) != 0)
    {
      //trace("FLAG_STOP");
      chan.sample = null;
    }
  }

  private function envelope(envelope:XMEnvelope, data:XMData, flag : Int, voice:XMVoice) : Void {
    var curr:XMPoint, currPos : Int, diff : Int, next:XMPoint, nextPos : Int;

    if (voice.isFading != 0) {
      voice.fadeout -= (voice.instrument.fadeout << 1);

      if (voice.fadeout < 0) {
        voice.fadeout = 0;
        voice.isFading = 0;
      }
    }

    if (envelope.stopped == 0) {
      currPos = envelope.position;
      curr = data.points[currPos];
  
      if (envelope.frame == curr.frame) {
        if ((data.flags & XM.ENVELOPE_LOOP) != 0 && currPos == data.loopEnd) {
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
    
        if ((data.flags & XM.ENVELOPE_SUSTAIN) != 0 && currPos == data.sustain && voice.keyoff == 0) {
          envelope.value = curr.value;
          voice.flags |= flag;
          return;
        }
    
        diff = next.frame - curr.frame;
    
        if (diff != 0) envelope.delta = Std.int(((next.value - curr.value) << 16) / diff);
          else envelope.delta = 0;
          //else envelope.delta = 0.0; <- delta is Int, why assign 0.0?
    
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
