/* FlodXM Alpha 3
   2011/09/17
   Christian Corti
   Neoart Costa Rica

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 	 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 	 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 	 IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package {
  import flash.display.*;
  import flash.events.*;
  import flash.net.*;
  import flash.utils.*;
  import neoart.flectrum.*;
  import neoart.flexi.*;
  import neoart.flip.*;
  import neoart.flod.core.*;
  import neoart.flod.xm.*;

  public final class FlodXM extends Sprite {
    private var
      file      : FileReference,
      mixer     : Soundblaster,
      player    : XMPlayer,
      btnPlay   : Button,
      btnPause  : Button,
      btnStop   : Button,
      btnLoad   : Button,
      btnRecord : ToggleButton,
      btnSave   : Button,
      btnLoop   : ToggleButton,
      btnVoices : Vector.<ToggleButton>,
      lblTitle  : Label,
      lblSample : Label,
      meters    : Flectrum,
      soundEx   : SoundEx,
      btnVis    : Button,
      btnMode   : Button,
      btnDir    : Button,
      currVis   : int,
      currMode  : int,
      currDir   : int;

    public function FlodXM() {
      stage.quality   = "high";
      stage.scaleMode = "noScale";

      btnPlay = new Button(this, 5, 5, "PLAY");
      btnPlay.addEventListener(MouseEvent.CLICK, playHandler);
      btnPause = new Button(this, 5, 24, "PAUSE");
      btnPause.addEventListener(MouseEvent.CLICK, pauseHandler);
      btnStop = new Button(this, 5, 43, "STOP");
      btnStop.addEventListener(MouseEvent.CLICK, stopHandler);

      btnLoad = new Button(this, 77, 5, "BROWSE");
      btnLoad.addEventListener(MouseEvent.CLICK, browseHandler);
      btnLoad.enabled = true;
      btnRecord = new ToggleButton(this, 77, 24, "REC OFF", "REC ON", 72);
      btnRecord.addEventListener(MouseEvent.CLICK, recordHandler);
      btnSave = new Button(this, 77, 43, "SAVE");
      btnSave.addEventListener(MouseEvent.CLICK, saveHandler);

      btnLoop = new ToggleButton(this, 149, 5, "LOOP OFF", "LOOP ON", 72);
      btnLoop.addEventListener(MouseEvent.CLICK, loopSongHandler);
      btnLoop.enabled = true;

      btnVoices = new Vector.<ToggleButton>();

      lblTitle  = new Label(this, 6,  63, "Welcome to FlodXM");
      lblSample = new Label(this, 6,  82, "Press the Browse button to start...");
      new Label(this, 6, 118, "Alpha 3 - 09/17/2011 - Christian Corti").color = 0xd2d6dc;

      btnVis  = new Button(this, 5, 99, "Default");
      btnVis.addEventListener(MouseEvent.CLICK, visualizerHandler);
      btnVis.enabled = true;
      btnMode = new Button(this, 77, 99, "Peaks");
      btnMode.addEventListener(MouseEvent.CLICK, modeHandler);
      btnMode.enabled = true;
      btnDir  = new Button(this, 149, 99, "Up");
      btnDir.addEventListener(MouseEvent.CLICK, directionHandler);
      btnDir.enabled = true;

      soundEx = new SoundEx();

      meters = new Flectrum(soundEx);
      meters.x = 222;
      meters.y =   6;
      meters.columnSize = 16;
      meters.columns    = 16;
      meters.rowSize    =  2;
      meters.rows       = 68;
      meters.addEventListener("soundStop", stopExHandler);
      addChild(meters);

      mixer  = new Soundblaster();
      player = new XMPlayer(mixer);
      player.addEventListener(Event.SOUND_COMPLETE, soundCompleteHandler);
    }

    private function browseHandler(e:MouseEvent):void {
      player.stop();
      file = new FileReference();
      file.addEventListener(Event.CANCEL, cancelHandler);
      file.addEventListener(Event.SELECT, selectHandler);
      file.browse([new FileFilter("FastTracker II", "*.xm;*.zip")]);
    }

    private function cancelHandler(e:Event):void {
      file.removeEventListener(Event.CANCEL, cancelHandler);
      file.removeEventListener(Event.SELECT, selectHandler);
    }

    private function selectHandler(e:Event):void {
      cancelHandler(e);
      file.addEventListener(Event.COMPLETE, loadCompleteHandler);
      file.load();
    }

    private function loadCompleteHandler(e:Event):void {
      var archive:ZipFile, sig:int, stream:ByteArray;
      file.removeEventListener(Event.COMPLETE, loadCompleteHandler);

      stream = file.data;
      sig = stream.readUnsignedInt();

      if (sig == 0x504b0304) {
        archive = new ZipFile(stream);
        stream = archive.uncompress(archive.entries[0]);
      }

      player.load(stream);
      file = null;

      if (player.version) {
        lblTitle.text  = player.title;
        lblSample.text = "";
        initialize();
      }
    }

    private function initialize():void {
      var button:ToggleButton, i:int, len:int, max:int = 221, tot:int, x:int = 5, y:int = 134;

      len = player.channels;
      tot = btnVoices.length;

      if (len > tot) {
        if (tot) {
          button = btnVoices[int(tot - 1)];
          x = button.x + 27;
          y = button.y;
        }

        for (i = tot; i < len; ++i) {
          if ((x + 27) > max) {
            x  = 5;
            y += 19;
          }

          button = new ToggleButton(this, x, y, String(i + 1), "OFF");
          button.addEventListener(MouseEvent.CLICK, toggleHandler);
          button.enabled = true;
          btnVoices[i] = button;
          x += 27;
        }
      } else if (len < tot) {
        for (i = --tot; i >= len; --i) {
          button = btnVoices[i];
          removeChild(button);
          button.removeEventListener(MouseEvent.CLICK, toggleHandler);
          btnVoices[i] = null;
        }

        btnVoices.length = len;
      }

      len = btnVoices.length;
      for (i = 0; i < len; ++i) btnVoices[i].pressed = false;

      btnPlay.enabled   = true;
      btnRecord.enabled = true;
    }

    private function playHandler(e:MouseEvent):void {
      player.play(soundEx);
      btnLoad.enabled   = false;
      btnRecord.enabled = false;
      btnSave.enabled   = false;
      btnPlay.enabled   = false;
      btnPause.enabled  = true;
      btnStop.enabled   = true;

      btnVis.enabled  = false;
      btnMode.enabled = false;
      btnDir.enabled  = false;
    }

    private function pauseHandler(e:MouseEvent):void {
      player.pause();
      btnPlay.enabled  = true;
      btnPause.enabled = false;
    }

    private function stopHandler(e:MouseEvent):void {
      player.stop();
      soundEx.stop();
      btnLoad.enabled   = true;
      btnRecord.enabled = true;
      btnSave.enabled   = btnRecord.pressed;
      btnPlay.enabled   = true;
      btnPause.enabled  = false;
      btnStop.enabled   = false;
    }

    private function soundCompleteHandler(e:Event):void {
      stopHandler(new MouseEvent(MouseEvent.CLICK));
    }

    private function toggleHandler(e:MouseEvent):void {
      var index = parseInt(Button(e.target).caption) - 1;
      mixer.channels[index].mute ^= 1;
    }

    private function loopSongHandler(e:MouseEvent):void {
      player.loopSong = int(btnLoop.pressed);
    }

    private function recordHandler(e:MouseEvent):void {
      mixer.record = int(btnRecord.pressed);
    }

    private function saveHandler(e:MouseEvent):void {
      file = new FileReference();
      file.addEventListener(Event.COMPLETE, saveCompleteHandler);
      file.save(mixer.waveform, "FlodXM.wav");
    }

    private function saveCompleteHandler(e:Event):void {
      file.removeEventListener(Event.COMPLETE, saveCompleteHandler);
      file = null;
      btnSave.enabled = false;
    }

    private function visualizerHandler(e:MouseEvent):void {
      if (++currVis > 4) currVis = 0;

      switch (currVis) {
        case 0:
          btnVis.caption = "Default";
          meters.visualizer = new Visualizer();
          meters.spectrum = SoundEx.SPECTRUM_BOTH;
          break;
        case 1:
          btnVis.caption = "Split";
          meters.visualizer = new Split();
          meters.spectrum = SoundEx.SPECTRUM_DOUBLE;
          break;
        case 2:
          btnVis.caption = "Stripe";
          meters.visualizer = new Stripe();
          meters.spectrum = SoundEx.SPECTRUM_DOUBLE;
          break;
        case 3:
          btnVis.caption = "Inward";
          meters.visualizer = new Inward();
          meters.spectrum = SoundEx.SPECTRUM_DOUBLE;
          break;
        case 4:
          btnVis.caption = "Outward";
          meters.visualizer = new Outward();
          meters.spectrum = SoundEx.SPECTRUM_DOUBLE;
          break;
      }
    }

    private function modeHandler(e:MouseEvent):void {
      if (++currMode > 2) currMode = 0;

      switch (currMode) {
        case 0:
          btnMode.caption = "Peaks";
          meters.mode = Flectrum.MODE_PEAKS;
          break;
        case 1:
          btnMode.caption = "Meter";
          meters.mode = Flectrum.MODE_METER;
          break;
        case 2:
          btnMode.caption = "Trail";
          meters.mode = Flectrum.MODE_TRAIL;
          break;
      }
    }

    private function directionHandler(e:MouseEvent):void {
      if (++currDir > 3) currDir = 0;

      switch (currDir) {
        case 0:
          btnDir.caption = "Up";
          meters.direction = Flectrum.DIRECTION_UP;
          meters.rowSize = 2;
          meters.columns = 16;
          break;
        case 1:
          btnDir.caption = "Left";
          meters.direction = Flectrum.DIRECTION_LEFT;
          meters.rowSize = 3;
          meters.columns = 12;
          break;
        case 2:
          btnDir.caption = "Down";
          meters.direction = Flectrum.DIRECTION_DOWN;
          meters.rowSize = 2;
          meters.columns = 16;
          break;
        case 3:
          btnDir.caption = "Right";
          meters.direction = Flectrum.DIRECTION_RIGHT;
          meters.rowSize = 3;
          meters.columns = 12;
          break;
      }
    }

    private function stopExHandler(e:Event):void {
      btnVis.enabled  = true;
      btnMode.enabled = true;
      btnDir.enabled  = true;
    }
  }
}