
class AppLogger {
  final bool enabled;
  const AppLogger({this.enabled = true});

  void log(String msg) {
    if (enabled) {
      // ignore: avoid_print
      print('[APP] $msg');
    }
  }
}
