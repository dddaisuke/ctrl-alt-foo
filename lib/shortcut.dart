library shortcut;

import 'package:ctrl_alt_foo/key_event_x.dart';
import 'key_identifier.dart';
import 'dart:html';
import 'dart:async';

class ShortCut {
  String char;
  bool isCtrl, isShift, isMeta;
  StreamSubscription subscription;
  var cb;

  static var _stream = KeyboardEventStream.onKeyDown(document.body);
  static var _streamController = new StreamController.broadcast();

  static get stream {
    _stream.listen((e) {_streamController.add(new KeyEventX(e));});
    return _streamController.stream;
  }

  static void dispatchEvent(KeyEvent e)=> _stream.add(e);

  static List subscriptions = [];
  static void removeAll() {
    while (ShortCut.subscriptions.length > 0) {
      ShortCut.subscriptions.removeLast().cancel();
    }
  }

  ShortCut(
    this.char,
    this.cb,
    {
      this.isCtrl: false,
      this.isShift: false,
      this.isMeta: false
    })
  { this._createStream(); }

  factory ShortCut.fromString(String k, callback) {
    var parts = k.
      replaceAll(new RegExp(r'\s+'), '').
      replaceAll('⌘', 'Meta').
      replaceAll('Command', 'Meta').
      split('+');

    var key = parts.removeLast();

    parts.sort();
    switch (parts.join('+')) {
      case '':
        new ShortCut(key, callback);
        break;
      case 'Ctrl':
        new ShortCut(key, callback, isCtrl: true);
        break;
      case 'Meta':
        new ShortCut(key, callback, isMeta: true);
        break;
      case 'Shift':
        new ShortCut(key, callback, isShift: true);
        break;
      case 'Ctrl+Shift':
        new ShortCut(key, callback, isCtrl: true, isShift: true);
        break;
      case 'Meta+Shift':
        new ShortCut(key, callback, isCtrl: true, isShift: true);
        break;
      default:
        throw new InvalidShortCutString(k);
    }
  }


  void cancel()=> subscription.cancel();

  void _createStream() {
    var key = char;
    if (char.length > 1) {
      if (!KeyIdentifier.containsKey(char)) {
        throw new InvalidKeyName("$char is not recognized");
      }
      key = KeyIdentifier.keyFor(char);
    }
    subscription = KeyboardEventStreamX.onKeyDown(document).listen((e) {
      if (!e.isKey(key)) return;

      if (e.isCtrl  != isCtrl) return;
      if (e.isShift != isShift) return;
      if (e.isMeta  != isMeta) return;

      e.preventDefault();
      cb();
    });

    subscriptions.add(subscription);
  }
}

class InvalidKeyName extends Error {
  final message;
  InvalidKeyName(this.message): super();
}

class InvalidShortCutString extends Error {
  final message;
  InvalidShortCutString(this.message): super();
}
