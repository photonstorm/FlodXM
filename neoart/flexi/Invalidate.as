/* Flexi 1.0
   2010/05/12
   Christian Corti
   Neoart Costa Rica

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 	 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 	 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 	 IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package neoart.flexi {

  public final class Invalidate {
    public static const
      ALL   : int = 0,
      DATA  : int = 1,
      SIZE  : int = 2,
      STATE : int = 3,
      STYLE : int = 4,
      SET   : int = 5;
    private var
      flags : int;

    public function isInvalid(index:int):Boolean {
      return Boolean((flags & (1 << (index & 31))) >> (index & 31));
    }

    public function reset():void {
      flags = 0;
    }

    public function invalidate(index:int):void {
      flags |= (1 << (index & 31));
    }

    public function validate(index:int):void {
      flags &= ~(1 << (index & 31));
    }
  }
}