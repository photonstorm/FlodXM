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
import flash.utils.Endian;
//import flash.Vector;

// TODO: replace Vector with flash.Memory
class SBSample 
{  
  public var name      : String;
  public var bits      : Int;
  public var length    : Int;
  public var loopStart : Int;
  public var loopLen   : Int;
  public var loopMode  : Int;
  public var volume    : Int;

  // haxe port: turn this into flash.Memory
  //public var data      : Vector<Float>;
  public var bytes (default, null) : ByteArray;

  public function new()
  {
    bits = 8;
    name = "";
  }

  public function store(stream : ByteArray) : Void 
  {
    var delta : Int = 0;
    //var i     : Int;
    var len   : Int = length;
    var total : Int;

    // original code: var value : Int
    var value : Int;

    //data = new Vector<Float>(len, true);
    bytes = new ByteArray();
    bytes.endian = Endian.LITTLE_ENDIAN;

    //var dataString : String = "";

    //trace("sample length: " + data.length);

    if (bits == 8) 
    {
      total = stream.position + len;
      // TODO: comparison of Int and UInt
      if (total > Std.int(stream.length))
        len = stream.length - stream.position;

      for (i in 0...len) 
      {
        value = stream.readByte() + delta;

        if (value > 127) 
        {
          value -= 256;
        }
        else if (value < -128) 
        {
          value += 256;
        }

        //data[i] = value * 0.0078125;
        bytes.writeFloat(value * 0.0078125);
        delta = value;
      }
    } 
    else 
    {
      total = stream.position + (len << 1);

      // TODO: comparison of Int and UInt
      if (total > Std.int(stream.length))
      {
        len = (stream.length - stream.position) >> 1;

        trace("length truncated!");
      }

      for (i in 0...len) 
      {
        value = stream.readShort() + delta;

        if (value > 32767) 
        {
          value -= 65536;
        }
        else if (value < -32768) 
        {
          value += 65536;
        }

        //data[i] = value * 0.00003051758;
        bytes.writeFloat(value * 0.00003051758);
        delta = value;

        //dataString = dataString + " " + data[i];
      }

      //trace(dataString);
    }

    fixLength();
  }

  public function fill(count : Int, value : Float)
  {
    bytes = new ByteArray();
    bytes.endian = Endian.LITTLE_ENDIAN;

    for(i in 0...count)
    {
      bytes.writeFloat(value);
    }

    fixLength();
  }

  // haxe.Memory needs a ByteArray with at least 1024 bytes in it
  // need to fill in the rest of the bytes
  private function fixLength()
  {
    if (bytes == null)
    {
      return;
    }
    
    if (bytes.position < 1024)
    {
      var fillCount : Int = ((1024 - bytes.position) >> 2) + 1;

      trace("fill bytes: " + fillCount);

      for(i in 0...fillCount)
      {
        bytes.writeFloat(0.0);
      }
    }
  }
}
