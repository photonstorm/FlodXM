import neoart.flod.core.Soundblaster;
import neoart.flod.xm.XMPlayer;
import neoart.flod.xm.XM;

import flash.display.Sprite;

class Test 
{
	public static function main() 
  {
    if(haxe.Firebug.detect())
    {       
      haxe.Firebug.redirectTraces();
    }		
    
      var loadingBar = new LoadingBar();
      flash.Lib.current.addChild(loadingBar);
    
    //try
    //{
      var mixer  = new Soundblaster();
      var player = new XMPlayer(mixer);
      //player.addEventListener(Event.SOUND_COMPLETE, soundCompleteHandler);

      trace("FT_SIN test: " + XM.FT2_SINE[1]);

      var version = player.load(new Data_Music());
      trace("loading track completed " + version);
      player.play();    
    /*}
    catch(e : Dynamic)
    {
      trace(e);
    }
    */
  }

  //private function soundCompleteHandler(e:Event):void 
  //{
  //}
}