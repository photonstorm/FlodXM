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

@final class XMEnvelope 
{
  public var value    : Int;
  public var position : Int;
  public var frame    : Int;
  public var delta    : Int;
  public var fraction : Int;
  public var stopped  : Int;

  public /*internal*/ function reset(value : Int) : Void 
  {
    this.value = value;
    position = 0;
    frame    = 0;
    delta    = 0;
    fraction = 0;
    stopped  = 0;
  }

  public function new()
  {
    //reset(0);
  }
}
