class LoadingBar extends flash.display.Sprite
{
  private var frame : flash.display.Shape;
  private var bar   : flash.display.Shape;

  private var barAlpha    : Float;
  private var barAlphaVel : Float;
  
  public function new()
  {
    super();

    createUI();

    addEventListener(flash.events.Event.ENTER_FRAME, onEnterFrame);
  }

  private function createUI()
  {
    // add a black background
    var bkg = new flash.display.Shape();
    
    bkg.graphics.lineStyle(1.0, 0x000000);
    bkg.graphics.beginFill(0xFFFFFF);
    bkg.graphics.drawRect(0, 0, 320, 240);
    bkg.graphics.endFill();

    addChild(bkg);

    // add the progress bar frame
    frame = new flash.display.Shape();

    frame.graphics.lineStyle(1.0, 0xFFFFFF);
    frame.graphics.drawRect(0, 0, 2 * Def.LOADING_BAR_H_SPACING + Def.LOADING_BAR_WIDTH, 2 * Def.LOADING_BAR_V_SPACING + Def.LOADING_BAR_HEIGHT);

    addChild(frame);

    frame.x = 320 / 2 - frame.width / 2;
    frame.y = 240 / 2 - frame.height / 2;

    // add the progress bar
    bar = new flash.display.Shape();
    bar.graphics.lineStyle(1.0, 0xFFFFFF);
    bar.graphics.beginFill(0xFFFFFF);
    bar.graphics.drawRect(0, 0, Def.LOADING_BAR_WIDTH, Def.LOADING_BAR_HEIGHT);
    bar.graphics.endFill();

    addChild(bar);

    bar.x = 320 / 2 - bar.width / 2;
    bar.y = 240 / 2 - bar.height / 2;

    bar.scaleX = 0.0;

    barAlpha = 1.0;
    barAlphaVel = -0.05;
  }

  function onEnterFrame(e: flash.events.Event) 
  {
    var totalBytes  = flash.Lib.current.loaderInfo.bytesTotal;
    var loadedBytes = flash.Lib.current.loaderInfo.bytesLoaded;

    bar.scaleX = loadedBytes / totalBytes;

    //trace(loadedBytes + "/" + totalBytes);

    // modify the alpha
    barAlpha += barAlphaVel;

    if (barAlpha < 0.5)
    {
      barAlphaVel = 0.05;
      barAlpha = 0.5;
    }

    if (barAlpha >= 1.0)
    {
      barAlphaVel = -0.05;
      barAlpha = 1.0;
    }
    
    bar.alpha   = barAlpha;
    frame.alpha = barAlpha;

    if (loadedBytes == totalBytes)
    {
      // de-activate this control
      removeEventListener(flash.events.Event.ENTER_FRAME, onEnterFrame);
    }
  }
}