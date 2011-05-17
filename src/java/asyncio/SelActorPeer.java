package fan.spectre;

import fan.sys.*;
import java.io.*;
import java.net.*;
import java.nio.*;
import java.nio.channels.*;
import static java.nio.channels.SelectionKey.*;
import java.util.Set;
import java.util.Map;
import java.util.HashMap;

public class SelActorPeer {
  public java.nio.channels.Selector _sel;
  public Map<SelectionKey, Object> _channels = new HashMap<SelectionKey, Object>();
  
  public static SelActorPeer make(SelActor selector) { return new SelActorPeer(); }
  public SelActorPeer() { 
    try { _sel = java.nio.channels.Selector.open(); }
    catch(IOException e) { throw IOErr.make(e).val; }
  }
  
  public void _register(SelActor fan, Object s) {
    if (s instanceof TcpSocket)
      _register(fan, (TcpSocket) s);
    else if (s instanceof TcpListener)
      _register(fan, (TcpListener) s);
    else
      throw ArgErr.make("SelActor#register accepts only TcpSocket or TcpListener, not " + s.getClass()).val;
  }

  public void _register(SelActor fan, TcpSocket s) {
    try {
      s.peer._ch.configureBlocking(false); // we need this for select to work
      SelectionKey key = s.peer._ch.register(_sel, OP_READ);
      _channels.put(key, s);
    } catch(IOException e) { throw IOErr.make(e).val; }
  }
  
  public void _register(SelActor fan, TcpListener s) {
    try {
      s.peer._ch.configureBlocking(false);
      SelectionKey key = s.peer._ch.register(_sel, OP_ACCEPT);
      _channels.put(key, s);
    } catch(IOException e) { throw IOErr.make(e).val; }
  }

  public void _unregister(SelActor fan, Object s) {
    if (s instanceof TcpSocket)
      _unregister(fan, (TcpSocket) s);
    else if (s instanceof TcpListener)
      _unregister(fan, (TcpListener) s);
    else
      throw ArgErr.make("SelActor#unregister accepts only TcpSocket or TcpListener, not " + s.getClass()).val;
  }
  
  public void _unregister(SelActor fan, TcpSocket s) {
    try {
      SelectionKey key = s.peer._ch.keyFor(_sel);
      if (key != null) {
        _channels.remove(key);
        key.cancel();
        
        // _sel.select() hangs if same socket was removed and registered again,
        // so we doing non-blocking selectNow in between.
        _sel.selectNow(); 
      }
    } catch(IOException e) { throw IOErr.make(e).val; }
  }
  
  public void _unregister(SelActor fan, TcpListener s) {
    try {
      SelectionKey key = s.peer._ch.keyFor(_sel);
      if (key != null) {
        _channels.remove(key);
        key.cancel();

        // _sel.select() hangs if same socket was removed and registered again,
        // so we doing non-blocking selectNow in between.
        _sel.selectNow();
      }
    } catch(IOException e) { throw IOErr.make(e).val; }
  }

  public void _wakeup(SelActor fan) {
    _sel.wakeup();
  }

  public void _select(SelActor fan) {
    try {
      _sel.select();
      Set<SelectionKey> readyKeys = _sel.selectedKeys();
      for (SelectionKey key: readyKeys) { // FIXME concurrent modification here
        readyKeys.remove(key);
        if (key.isAcceptable()) {          
          TcpListener l = (TcpListener) _channels.get(key);
          _unregister(fan, l);
          l.acceptReady.call(fan, l);
          break; // FIXME take a look at concurrent modification above
        } else if (key.isReadable()) {
          TcpSocket s = (TcpSocket) _channels.get(key);
          _unregister(fan, s);
          s.peer._ch.configureBlocking(true); // TODO configure this in socket
          s.readReady.call(fan, s);
          break; // FIXME take a look at concurrent modification above
        }
      }
    } catch(IOException e) { throw IOErr.make(e).val; }
  }
}