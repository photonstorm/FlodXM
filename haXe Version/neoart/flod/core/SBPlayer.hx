/* FlodXM Alpha 3
   2011/09/17
   Christian Corti
   Neoart Costa Rica

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 	 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 	 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 	 IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package neoart.flod.core;

import flash.utils.ByteArray;
import flash.events.EventDispatcher;
import flash.events.Event;
import flash.events.SampleDataEvent;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.Vector;

class SBPlayer extends EventDispatcher 
{
  public static inline var ENCODING  : String = "us-ascii";
  
  public var mixer     : Soundblaster;
  public var channels  : Int;
  public var version   : Int;
  public var title     : String;
  public var length    : Int;
  public var restart   : Int;
  public var speed     : Int;
  public var tempo     : Int;
  public var loopSong  : Int;
  public var track     : Vector<Int>;
  public var counter   : Int;
  public var master (default, setMaster) : Int;

  // protected
  private var sound     : Sound;
  private var soundChan : SoundChannel;
  private var soundPos  : Float;
  private var timer     : Int;

  public function new(mixer:Soundblaster = null) 
  {
    super();
    
    this.mixer = (mixer == null) ? new Soundblaster() : mixer;
    this.mixer.player = this;

    loopSong = 0;
    soundPos = 0.0;
    title = "";

    master  = 64;
  }

  public function load(stream:ByteArray) : Int 
  {
    version = 0;
    stream.endian = flash.utils.Endian.LITTLE_ENDIAN;//"littleEndian";
    stream.position = 0;
    return version;
  }

  public function play(processor:Sound = null) : Int 
  {
    // !version
    if (version == 0) return 0;
    if (soundPos == 0.0) initialize();
    sound = (processor == null) ? new Sound() : processor;
    sound.addEventListener(SampleDataEvent.SAMPLE_DATA, mixer.mix);

    soundChan = sound.play(soundPos);
    soundChan.addEventListener(Event.SOUND_COMPLETE, completeHandler);
    soundPos = 0.0;
    return 1;
  }

  public function pause() : Void 
  {
    // !version
    if (version == 0 || soundChan == null)
    {
      return;
    }

    soundPos = soundChan.position;
    removeEvents();
  }

  public function stop() : Void 
  {
    // !version
    if (version == 0) return;
    if (soundChan != null) removeEvents();
    soundPos = 0.0;
    reset();
  }

  public function process() : Void { }

  private function setup() : Void 
  {
    mixer.setup(channels);
  }

  private function initialize() : Void 
  {
    mixer.initialize();
    counter = speed;
    timer   = 0;
    mixer.samplesTick = Std.int(110250 / tempo);

    trace(counter);
  }

  private function reset() : Void { }

  private function completeHandler(e : Event) : Void 
  {
    stop();
    dispatchEvent(e);
  }

  private function removeEvents() : Void 
  {
    soundChan.stop();
    soundChan.removeEventListener(Event.SOUND_COMPLETE, completeHandler);
    sound.removeEventListener(SampleDataEvent.SAMPLE_DATA, mixer.mix);
  }

  private function setMaster(v : Int) : Int
  {
    if (v > 64) 
    {
      v = 64;
    }

    if (v < 0)
    {
      v = 0;
    }

    master = v;
    
    return master;
  }
}
