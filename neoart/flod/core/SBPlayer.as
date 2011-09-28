/* FlodXM Alpha 3
   2011/09/17
   Christian Corti
   Neoart Costa Rica

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 	 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 	 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 	 IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package neoart.flod.core {
  import flash.events.*;
  import flash.media.*;
  import flash.utils.*;

  public class SBPlayer extends EventDispatcher {
    public static const
      ENCODING  : String = "us-ascii";
    public var
      mixer     : Soundblaster,
      channels  : int,
      version   : int,
      title     : String = "",
      length    : int,
      restart   : int,
      speed     : int,
      tempo     : int,
      loopSong  : int,
      track     : Vector.<int>,
      counter   : int;
    protected var
      sound     : Sound,
      soundChan : SoundChannel,
      soundPos  : Number,
      timer     : int,
      master    : int;

    public function SBPlayer(mixer:Soundblaster = null) {
      this.mixer = mixer || new Soundblaster();
      this.mixer.player = this;
      loopSong = 0;
      soundPos = 0.0;
    }

    public function load(stream:ByteArray):int {
      version = 0;
      stream.endian = "littleEndian";
      stream.position = 0;
      return version;
    }

    public function play(processor:Sound = null):int {
      if (!version) return 0;
      if (soundPos == 0.0) initialize();
      sound = processor || new Sound();
      sound.addEventListener(SampleDataEvent.SAMPLE_DATA, mixer.mix);

      soundChan = sound.play(soundPos);
      soundChan.addEventListener(Event.SOUND_COMPLETE, completeHandler);
      soundPos = 0.0;
      return 1;
    }

    public function pause():void {
      if (!version || !soundChan) return;
      soundPos = soundChan.position;
      removeEvents();
    }

    public function stop():void {
      if (!version) return;
      if (soundChan) removeEvents();
      soundPos = 0.0;
      reset();
    }

    public function process():void { }

    protected function setup():void {
      mixer.setup(channels);
    }

    protected function initialize():void {
      mixer.initialize();
      counter = speed;
      timer   = 0;
      master  = 64;
      mixer.samplesTick = 110250 / tempo;
    }

    protected function reset():void { }

    private function completeHandler(e:Event):void {
      stop();
      dispatchEvent(e);
    }

    private function removeEvents():void {
      soundChan.stop();
      soundChan.removeEventListener(Event.SOUND_COMPLETE, completeHandler);
      sound.removeEventListener(SampleDataEvent.SAMPLE_DATA, mixer.mix);
    }
  }
}