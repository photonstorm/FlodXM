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

import neoart.flod.core.SBChannel;

@final class XMVoice 
{
  public var index            : Int;
  public var next             : XMVoice;
  public var channel          : SBChannel;
  public var flags            : Int;
  public var note             : Int;
  public var target           : Int;
  public var period           : Int;
  public var frequency        : Int;
  public var frqDelta         : Int;
  public var delay            : Int;
  public var keyoff           : Int;
  public var instrument       : XMInstrument;
  public var autoVibratoPos   : Int;
  public var autoSweepPos     : Int;
  public var sample           : XMSample;
  public var finetune         : Int;
  public var sampleOffset     : Int;
  public var patternLoopRow   : Int;
  public var patternLoopCnt   : Int;
  public var fadeout          : Int;
  public var isFading         : Int;
  public var volume           : Int;
  public var volSlide         : Int;
  public var volSlideMaster   : Int;
  public var fineVolSlideUp   : Int;
  public var fineVolSlideDown : Int;
  public var volEnvelope      : XMEnvelope;
  public var panning          : Int;
  public var panSlide         : Int;
  public var panEnvelope      : XMEnvelope;
  public var arpeggioOn       : Int;
  public var portaDown        : Int;
  public var portaUp          : Int;
  public var finePortaUp      : Int;
  public var finePortaDown    : Int;
  public var xtraPortaUp      : Int;
  public var xtraPortaDown    : Int;
  public var portaPeriod      : Int;
  public var portaSpeed       : Int;
  public var vibratoOn        : Int;
  public var vibratoPos       : Int;
  public var vibratoSpeed     : Int;
  public var vibratoDepth     : Int;
  public var tremoloPos       : Int;
  public var tremoloSpeed     : Int;
  public var tremoloDepth     : Int;
  public var waveControl      : Int;
  public var tremorPos        : Int;
  public var tremorOn         : Int;
  public var tremorOff        : Int;
  public var tremorVol        : Int;
  public var retrigX          : Int;
  public var retrigY          : Int;
  public var volTemp          : Int;

  public function new(index: Int) 
  {
    this.index = index;
    volEnvelope = new XMEnvelope();
    panEnvelope = new XMEnvelope();

    flags = 0;

    //reset();
  }

  public function reset() : Void 
  {
    volume   = sample.volume;
    volTemp = volume;
    panning  = sample.panning;
    finetune = sample.finetune;
    keyoff   = 0;
    fadeout  = 65536;
    isFading = 0;

    volEnvelope.reset(64);
    panEnvelope.reset(32);

    autoVibratoPos = 0;
    autoSweepPos   = 0;
    tremorPos      = 0;

    if ((waveControl & 15) < 4) vibratoPos = 0;
    if ((waveControl >> 4) < 4) tremoloPos = 0;

    flags |= (XM.FLAG_VOLUME | XM.FLAG_PANNING);
  }

  public function autoVibrato() : Void 
  {
    var delta: Int = 0;

    if (++autoSweepPos > instrument.vibratoSweep)
      autoSweepPos = instrument.vibratoSweep;

    autoVibratoPos = (autoVibratoPos + instrument.vibratoSpeed) & 255;

    switch (instrument.vibratoType) 
    {
      case 0:
      {
        delta = XM.FT2_SINE[autoVibratoPos];
      }
      case 1:
      {
        if (autoVibratoPos < 128) delta = -64;
          else delta = 64;
      }
      case 2:
      {
        delta = ((64 + (autoVibratoPos >> 1)) & 127) - 64;
      }
      case 3:
      {
        delta = ((64 - (autoVibratoPos >> 1)) & 127) - 64;
      }
    }

    delta *= instrument.vibratoDepth;
    if (instrument.vibratoSweep != 0)
      delta = Std.int(delta * (autoSweepPos / instrument.vibratoSweep));

    frqDelta = (delta >> 6);
    flags |= XM.FLAG_PERIOD;
  }

  public function tonePortamento() : Void 
  {
    if (period < portaPeriod) 
    {
      period += portaSpeed << 2;
      if (period > portaPeriod) period = portaPeriod;
    } 
    else if (period > portaPeriod) 
    {
      period -= portaSpeed << 2;
      if (period < portaPeriod) period = portaPeriod;
    }

    frequency = period;
    flags |= XM.FLAG_PERIOD;
  }

  public function tremolo() : Void 
  {
    var delta: Int = 0;
    var position: Int = tremoloPos & 31;
    var value: Int;

    switch ((waveControl >> 4) & 3) 
    {
      case 0:
      {
        delta = XM.MOD_SINE[position];
      }
      case 1:
      {
        delta = position << 3;
      }
      case 2:
      {
        delta = 255;
      }
    }

    value = (delta * tremoloDepth) >> 6;

    if (tremoloPos > 31) volume = volTemp - value;
      else volume = volTemp + value;

    tremoloPos = (tremoloPos + tremoloSpeed) & 63;
    flags |= XM.FLAG_VOLUME;
  }

  public function vibrato() : Void 
  {
    var delta: Int;
    var position: Int = vibratoPos & 31;
    var value: Int;

    switch (waveControl & 3) 
    {
      case 0:
      {
        delta = XM.MOD_SINE[position];
      }
      case 1:
      {
        delta = position << 3;
        if (vibratoPos > 31) delta = 255 - delta;
      }
      default:
      {
        delta = 255;
      }
    }

    value = (delta * vibratoDepth) >> 7;

    if (vibratoPos > 31) frequency = period - value;
      else frequency = period + value;

    vibratoPos = (vibratoPos + vibratoSpeed) & 63;
    flags |= XM.FLAG_PERIOD;
  }

  public function tremor() : Void 
  {
    if (tremorPos >= tremorOn) 
    {
      tremorVol = volume;
      volume = 0;
      flags |= XM.FLAG_VOLUME;
    }

    if (++tremorPos >= tremorOff) 
    {
      tremorPos = 0;
      volume = tremorVol;
      flags |= XM.FLAG_VOLUME;
    }
  }
}
