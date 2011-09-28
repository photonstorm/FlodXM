/* Flectrum version 1.1
   2009/08/31
   Christian Corti
   Neoart Costa Rica

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 	 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 	 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 	 IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package neoart.flectrum {
  import flash.display.*;
  import flash.geom.*;

  public class Visualizer extends Bitmap {
    internal var input:BitmapData;
    internal var levels:Vector.<Number>;
    internal var meters:Vector.<Number>;
    internal var sectionWidth:int;
    internal var sectionHeight:int;

    protected var flectrum:Flectrum;
    protected var buffer:BitmapData;
    protected var destPoint:Point;
    protected var sourceRect:Rectangle;

    protected var m_width:int;
    protected var m_height:int;

    public function Visualizer() {
      super(null, "always", true);
    }

    internal function initialize(flectrum:Flectrum):void {
      this.flectrum = flectrum;
      destPoint = new Point();
      sourceRect = new Rectangle();
    }

    internal function override():void {
      if (flectrum.m_spectrum == SoundEx.SPECTRUM_DOUBLE)
        flectrum.m_spectrum = SoundEx.SPECTRUM_BOTH;
    }

    internal function reset():void {
      rotation = x = y = 0;
      sectionHeight = flectrum.m_rowSize + flectrum.m_rowSpacing;

      if (flectrum.meter) {
        sectionWidth  = flectrum.meter.width + flectrum.m_colSpacing;
        m_width  = flectrum.m_columns * sectionWidth;
        m_height = flectrum.meter.height + flectrum.m_rowSpacing;
        clone();
      } else {
        sectionWidth  = flectrum.m_colSize + flectrum.m_colSpacing;
        m_width  = flectrum.m_columns * sectionWidth;
        m_height = flectrum.m_rows * sectionHeight;
        draw();
      }
    }

    internal function meterUpdate(spectrum:Vector.<Number>):void {
      var h:int, i:int, s:Number;
      sourceRect.x = 0;
      buffer.fillRect(buffer.rect, 0);

      for (i = 0; i < flectrum.m_columns; ++i) {
        s = spectrum[i];
        if (s > levels[i]) levels[i] = s;
        h = Math.ceil(levels[i] * flectrum.m_rows) * sectionHeight;

        sourceRect.y = m_height - h;
        sourceRect.height = h;
        buffer.fillRect(sourceRect, 0xff000000);

        sourceRect.x += sectionWidth;
        levels[i] -= flectrum.m_decay;
      }
      bitmapData.copyPixels(input, input.rect, destPoint, buffer);
    }

    internal function peaksUpdate(spectrum:Vector.<Number>):void {
      var h:int, i:int, s:Number;
      sourceRect.x = 0;
      buffer.fillRect(buffer.rect, 0);

      for (i = 0; i < flectrum.m_columns; ++i) {
        s = spectrum[i];
        if (s > meters[i]) meters[i] = s;
        h = Math.ceil(meters[i] * flectrum.m_rows) * sectionHeight;

        sourceRect.y = m_height - h;
        sourceRect.height = h;
        buffer.fillRect(sourceRect, 0xff000000);

        if (s > levels[i]) {
          levels[i] = s;
        } else {
          h = Math.ceil(levels[i] * flectrum.m_rows) * sectionHeight;
          sourceRect.y = m_height - h;
        }
        sourceRect.height = flectrum.m_rowSize;
        buffer.fillRect(sourceRect, flectrum.m_peaksAlpha);

        sourceRect.x += sectionWidth;
        meters[i] -= flectrum.m_decay;
        levels[i] -= flectrum.m_peaksDecay;
      }
      bitmapData.copyPixels(input, input.rect, destPoint, buffer);
    }

    internal function trailUpdate(spectrum:Vector.<Number>):void {
      var h:int, i:int;
      sourceRect.x = 0;
      buffer.fillRect(buffer.rect, flectrum.m_trailAlpha);
      bitmapData.copyPixels(bitmapData, bitmapData.rect, destPoint, buffer);
      buffer.fillRect(buffer.rect, 0);

      for (i = 0; i < flectrum.m_columns; ++i) {
        h = Math.ceil(spectrum[i] * flectrum.m_rows) * sectionHeight;
        sourceRect.y = m_height - h;
        sourceRect.height = h;

        buffer.fillRect(sourceRect, 0xff000000);
        sourceRect.x += sectionWidth;
      }
      bitmapData.copyPixels(input, input.rect, destPoint, buffer, null, true);
    }

    protected function clone():void {
      var i:int;
      buffer = new BitmapData(m_width, flectrum.meter.height, true, 0);
      buffer.lock();
      destPoint.x = 0;

      for (i = 0; i < flectrum.m_columns; ++i) {
        buffer.copyPixels(flectrum.meter, flectrum.meter.rect, destPoint);
        destPoint.x += sectionWidth;
      }
      levels = new Vector.<Number>(flectrum.m_columns, true);
      meters = new Vector.<Number>(flectrum.m_columns, true);
      finalizeClone();
    }

    protected function draw():void {
      var s:Shape = new Shape(), g:Graphics = s.graphics, m:Matrix = new Matrix();

      m.createGradientBox(m_width, m_height, Math.PI * 0.5, 0, 0);
      g.beginGradientFill("linear", flectrum.m_colors[0], flectrum.m_alphas[0], flectrum.m_ratios[0], m);
      g.drawRect(0, 0, m_width, m_height);

      levels = new Vector.<Number>(flectrum.m_columns, true);
      meters = new Vector.<Number>(flectrum.m_columns, true);
      finalizeDraw(s);
    }

    protected function finalizeClone():void {
      var i:int;
      flectrum.m_rows = m_height / sectionHeight;
      //need to check for invalid rows;

      if (flectrum.m_rowSpacing > 0) {
        sourceRect.width = m_width;
        sourceRect.height = flectrum.m_rowSpacing;
        sourceRect.x = 0;
        sourceRect.y = m_height - flectrum.m_rowSpacing;

        for (i = 0; i < flectrum.m_rows; ++i) {
          buffer.fillRect(sourceRect, 0);
          sourceRect.y -= sectionHeight;
        }
      }
      buffer.unlock();
      destPoint.x = 0;
      destPoint.y = 0;
      sourceRect.width = flectrum.m_colSize = flectrum.meter.width;

      input = new BitmapData(buffer.width, buffer.height, true, 0);
      input.threshold(buffer, buffer.rect, destPoint, "==", 0xff000000, 0x00ffffff, 0xffffffff, true);
      buffer.fillRect(buffer.rect, 0);
      bitmapData = buffer.clone();
    }

    protected function finalizeDraw(shape:Shape):void {
      var g:Graphics = shape.graphics, i:int, s:int = flectrum.m_rowSize;

      if (flectrum.m_rowSpacing > 0) {
        for (i = 0; i < flectrum.m_rows; ++i) {
          g.beginFill(0, 1);
          g.drawRect(0, s, m_width, flectrum.m_rowSpacing);
          s += sectionHeight;
        }
      }
      s = flectrum.m_colSize;
      sourceRect.width = s;

      if (flectrum.m_colSpacing > 0) {
        for (i = 0; i < flectrum.m_columns; ++i) {
          g.beginFill(0, 1);
          g.drawRect(s, 0, flectrum.m_colSpacing, m_height);
          s += sectionWidth;
        }
      }
      g.endFill();

      input = new BitmapData(m_width - flectrum.m_colSpacing, m_height - flectrum.m_rowSpacing, true, 0);
      buffer = input.clone();
      buffer.draw(shape);
      input.threshold(buffer, buffer.rect, destPoint, "==", 0xff000000, 0x00ffffff, 0xffffffff, true);
      buffer.fillRect(buffer.rect, 0);
      bitmapData = buffer.clone();
    }

    protected function scale(mirror:Boolean, flip:Boolean):Vector.<uint> {
      var i:int, l:Vector.<uint>, v:Vector.<uint> = new Vector.<uint>();

      if (mirror) {
        sourceRect.x = 0;
        sourceRect.y = 0;
        sourceRect.width = flectrum.meter.width;
        sourceRect.height = 1;

        for (i = 0; i < flectrum.meter.height; ++i) {
          l = flectrum.meter.getVector(sourceRect);
          l.reverse();
          v = v.concat(l);
          sourceRect.y++;
        }
      } else {
        v = flectrum.meter.getVector(flectrum.meter.rect);
      }

      if (flip) v.reverse();
      return v;
    }
  }
}