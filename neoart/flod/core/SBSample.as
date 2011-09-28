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
  import flash.utils.*;

  public class SBSample {
    public var
      name      : String = "",
      bits      : int = 8,
      length    : int,
      loopStart : int,
      loopLen   : int,
      loopMode  : int,
      volume    : int,
      data      : Vector.<Number>;

    public function store(stream:ByteArray):void {
      var delta:int, i:int, len:int = length, total:int, value:int;
      data = new Vector.<Number>(len, true);

      if (bits == 8) {
        total = stream.position + len;
        if (total > stream.length)
          len = stream.length - stream.position;

        for (i = 0; i < len; ++i) {
          value = stream.readByte() + delta;
          if (value > 127) value -= 256;
            else if (value < -128) value += 256;

          data[i] = value * 0.0078125;
          delta = value;
        }
      } else {
        total = stream.position + (len << 1);
        if (total > stream.length)
          len = (stream.length - stream.position) >> 1;

        for (i = 0; i < len; ++i) {
          value = stream.readShort() + delta;
          if (value > 32767) value -= 65536;
            else if (value < -32768) value += 65536;

          data[i] = value * 0.00003051758;
          delta = value;
        }
      }
    }
  }
}