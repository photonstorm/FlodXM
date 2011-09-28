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

  public class Stripe extends Visualizer {
    private var columns:int;

    public function Stripe() {
      super();
    }

    override internal function override():void {
      flectrum.m_spectrum = SoundEx.SPECTRUM_BOTH;
      flectrum.stereo = false;
    }

    override internal function meterUpdate(spectrum:Vector.<Number>):void {
      var h:int, i:int, r:int = columns, s:Number;
      sourceRect.x = 0;
      buffer.fillRect(buffer.rect, 0);

      for (i = 0; i < columns; ++i) {
        s = spectrum[i];
        if (s > levels[i]) levels[i] = s;
        h = Math.ceil(levels[i] * flectrum.m_rows) * sectionHeight;
        sourceRect.y = m_height - h;
        sourceRect.height = h;
        buffer.fillRect(sourceRect, 0xff000000);
        sourceRect.x += sectionWidth;

        s = spectrum[r];
        if (s > levels[r]) levels[r] = s;
        h = Math.ceil(levels[r] * flectrum.m_rows) * sectionHeight;
        sourceRect.y = 0;
        sourceRect.height = h;
        buffer.fillRect(sourceRect, 0xff000000);
        sourceRect.x += sectionWidth;

        levels[i] -= flectrum.m_decay;
        levels[r] -= flectrum.m_decay;
        ++r;
      }
      bitmapData.copyPixels(input, input.rect, destPoint, buffer);
    }

    override internal function peaksUpdate(spectrum:Vector.<Number>):void {
      var h:int, i:int, r:int = columns, s:Number
      sourceRect.x = 0;
      buffer.fillRect(buffer.rect, 0);

      for (i = 0; i < columns; ++i) {
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
        buffer.fillRect(sourceRect, 0xff000000);
        sourceRect.x += sectionWidth;

        s = spectrum[r];
        if (s > meters[r]) meters[r] = s;
        h = Math.ceil(meters[r] * flectrum.m_rows) * sectionHeight;
        sourceRect.y = 0;
        sourceRect.height = h;
        buffer.fillRect(sourceRect, 0xff000000);

        if (s > levels[r]) {
          levels[r] = s;
        } else {
          h = Math.ceil(levels[r] * flectrum.m_rows) * sectionHeight;
          sourceRect.y = h;
        }
        sourceRect.y -= sectionHeight;
        sourceRect.height = flectrum.m_rowSize;
        buffer.fillRect(sourceRect, 0xff000000);
        sourceRect.x += sectionWidth;

        meters[i] -= flectrum.m_decay;
        levels[i] -= flectrum.m_peaksDecay;
        meters[r] -= flectrum.m_decay;
        levels[r] -= flectrum.m_peaksDecay;
        ++r;
      }
      bitmapData.copyPixels(input, input.rect, destPoint, buffer);
    }

    override internal function trailUpdate(spectrum:Vector.<Number>):void {
      var h:int, i:int, r:int = columns;
      sourceRect.x = 0;
      buffer.fillRect(buffer.rect, flectrum.m_trailAlpha);
      bitmapData.copyPixels(bitmapData, bitmapData.rect, destPoint, buffer);
      buffer.fillRect(buffer.rect, 0);

      for (i = 0; i < columns; ++i) {
        h = Math.ceil(spectrum[i] * flectrum.m_rows) * sectionHeight;
        sourceRect.y = m_height - h;
        sourceRect.height = h;
        buffer.fillRect(sourceRect, 0xff000000);
        sourceRect.x += sectionWidth;

        h = Math.ceil(spectrum[r] * flectrum.m_rows) * sectionHeight;
        sourceRect.y = 0;
        sourceRect.height = h;
        buffer.fillRect(sourceRect, 0xff000000);
        sourceRect.x += sectionWidth;
        ++r;
      }
      bitmapData.copyPixels(input, input.rect, destPoint, buffer, null, true);
    }

    override protected function clone():void {
      var i:int, v:Vector.<uint>;

      if ((flectrum.m_columns & 1) != 0) {
        flectrum.m_columns--;
        m_width -= sectionWidth;
      }
      buffer = new BitmapData(m_width, flectrum.meter.height, true, 0);
      buffer.lock();
      destPoint.x = 0;
      columns = flectrum.m_columns >> 1;
      v = scale(true, true);

      sourceRect.x = sectionWidth;
      sourceRect.y = 0;
      sourceRect.width = flectrum.meter.width;
      sourceRect.height = flectrum.meter.height;

      for (i = 0; i < columns; ++i) {
        buffer.copyPixels(flectrum.meter, flectrum.meter.rect, destPoint);
        destPoint.x += (sectionWidth << 1);
        buffer.setVector(sourceRect, v);
        sourceRect.x += (sectionWidth << 1);
      }
      levels = new Vector.<Number>(flectrum.m_columns, true);
      meters = new Vector.<Number>(flectrum.m_columns, true);
      finalizeClone();
    }

    override protected function draw():void {
      var i:int, s:Shape = new Shape(), g:Graphics = s.graphics, m:Matrix = new Matrix(), t:int, w:int;

      if ((flectrum.m_columns & 1) != 0) {
        flectrum.m_columns--;
        m_width -= sectionWidth;
      }
      w = m_width >> 1;
      columns = flectrum.m_columns >> 1;

      m.createGradientBox(w, m_height, Math.PI * 0.5, 0, 0);
      g.beginGradientFill("linear", flectrum.m_colors[0], flectrum.m_alphas[0], flectrum.m_ratios[0], m);

      for (i = 0; i < columns; ++i) {
        g.drawRect(t, 0, sectionWidth, m_height);
        t += (sectionWidth << 1);
      }
      t = sectionWidth;

      m.createGradientBox(w, m_height, Math.PI * 1.5, 0, 0);
      g.beginGradientFill("linear", flectrum.m_colors[1], flectrum.m_alphas[1], flectrum.m_ratios[1], m);

      for (i = 0; i < columns; ++i) {
        g.drawRect(t, 0, sectionWidth, m_height);
        t += (sectionWidth << 1);
      }
      levels = new Vector.<Number>(flectrum.m_columns, true);
      meters = new Vector.<Number>(flectrum.m_columns, true);
      finalizeDraw(s);
    }
  }
}