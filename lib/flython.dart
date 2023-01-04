library flython;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mutex/mutex.dart';
import 'package:uuid/uuid.dart';

/// Flython let's you combine the power of Python with Dart.
/// It's meant to be used for creating powerful backend and logic code for beautiful Flutter apps, but it doesn't depend on Flutter and can be used in pure Dart code.
/// Make sure to subclass and use. See the package home page for an example.

class Flython {
  static const _mainAppContents = '''
import argparse
import json
import sys

CMD_SYS_VERSION = 0


def run(command):
    if command["cmd"] == CMD_SYS_VERSION:
        return {
            "sys.version": sys.version,
        }

    else:
        return {"error": "Unknown command."}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--uuid")
    args = parser.parse_args()
    stream_start = f"`S`T`R`E`A`M`{args.uuid}`S`T`A`R`T`"
    stream_end = f"`S`T`R`E`A`M`{args.uuid}`E`N`D`"
    while True:
        cmd = input()
        cmd = json.loads(cmd)
        try:
            result = run(cmd)
        except Exception as e:
            result = {"exception": e.__str__()}
        result = json.dumps(result)
        print(stream_start + result + stream_end)

''';

  final _instanceUuid = const Uuid().v4();
  var _resultCompleter = Completer();
  late String _result;
  late Process _process;
  final _runCmdMutex = Mutex();

  /// Python system version command code.
  /// This command code is part of the base Flython class mainly for demonstration purposes.
  static const cmdSysVersion = 0;

  String _streamStart() => "`S`T`R`E`A`M`$_instanceUuid`S`T`A`R`T`";

  String _streamEnd() => "`S`T`R`E`A`M`$_instanceUuid`E`N`D`";

  bool _debugMode = false;
  final _logFile = File(
      "./" + DateTime.now().toIso8601String().replaceAll(":", "-") + ".log");

  /// Log anything into the log file.
  /// Works only if Flython class (or subclass) is initialized in debug mode.
  void log(String text) {
    if (_debugMode) {
      print(text);
      _logFile.writeAsStringSync(
        DateTime.now().toIso8601String() + " => " + text + "\n\n",
        mode: FileMode.append,
      );
    }
  }

  /// Initializes Flython.
  /// [pythonCommand] is the actual Python executable, or command callable from any terminal.
  /// On Windows, for instance, if Python installation folder is in PATH, [pythonCommand] is set to `python.exe`
  /// [mainApp] is the path to the main Python script.
  /// If the provided path does not contain a script, then a new one will be created using the default contents below:
  /// ```
  /// import argparse
  /// import json
  /// import sys
  ///
  /// CMD_SYS_VERSION = 0
  ///
  ///
  /// def run(command):
  ///     if command["cmd"] == CMD_SYS_VERSION:
  ///         return {
  ///             "sys.version": sys.version,
  ///         }
  ///
  ///     else:
  ///         return {"error": "Unknown command."}
  ///
  ///
  /// if __name__ == "__main__":
  ///     parser = argparse.ArgumentParser()
  ///     parser.add_argument("--uuid")
  ///     args = parser.parse_args()
  ///     stream_start = f"`S`T`R`E`A`M`{args.uuid}`S`T`A`R`T`"
  ///     stream_end = f"`S`T`R`E`A`M`{args.uuid}`E`N`D`"
  ///     while True:
  ///         cmd = input()
  ///         cmd = json.loads(cmd)
  ///         try:
  ///             result = run(cmd)
  ///         except Exception as e:
  ///             result = {"exception": e.__str__()}
  ///         result = json.dumps(result)
  ///         print(stream_start + result + stream_end)
  /// ```
  /// [debugMode] can be used to log all commands that go in and out of the Python pipeline.
  /// Use this wisely and make sure your logs don't contain any sensitive information.
  /// Also make sure to not leave this on in production environments.
  /// The path to the file is created using the following code:
  /// ```
  /// "./" + DateTime.now().toIso8601String().replaceAll(":", "-") + ".log"
  /// ```
  Future<bool> initialize(
    String pythonCommand,
    String mainApp,
    bool debugMode,
  ) async {
    if (!File(mainApp).existsSync()) {
      File(mainApp).writeAsStringSync(_mainAppContents);
    }
    _debugMode = debugMode;
    if (_debugMode) _logFile.openWrite();
    return await _runCmdMutex.protect<bool>(() async {
      return await _initializeUnprotected(pythonCommand, mainApp);
    });
  }

  /// Force kill Python instance.
  /// Ideally, your application should implement an exit command that gracefully exits Python.
  void finalize() {
    _process.kill();
  }

  Future<bool> _initializeUnprotected(
    String pythonCommand,
    String mainApp,
  ) async {
    _process = await Process.start(
      pythonCommand,
      [mainApp, "--uuid", _instanceUuid],
    );
    _process.stdout.transform(utf8.decoder).forEach((element) {
      log(element);
      _result += element;
      if (_result.contains(_streamEnd()) && !_resultCompleter.isCompleted) {
        _resultCompleter.complete(_result
            .split(_streamStart())[1]
            .replaceAll(_streamEnd(), "")
            .trim());
      }
    });
    _process.stderr.transform(utf8.decoder).forEach((element) {
      log(element);
    });
    return true;
  }

  Future<dynamic> _runCommandUnprotected(dynamic command) async {
    final jsCommand = jsonEncode(command);
    _resultCompleter = Completer();
    _result = "";
    _process.stdin.writeln(jsCommand);
    log(jsCommand);
    final jsResult = await _resultCompleter.future;
    return jsonDecode(jsResult);
  }

  /// Sends a command to Python and returns the result.
  /// Try to avoid using this command directly in your applications.
  /// Instead, call it inside a method with proper input and output types.
  Future<dynamic> runCommand(dynamic command) async {
    return await _runCmdMutex.protect<dynamic>(() async {
      return await _runCommandUnprotected(command);
    });
  }

  /// An example command that returns Python system version.
  /// Same as running `sys.version` in Python.
  Future<dynamic> sysVersion() async {
    var command = {"cmd": cmdSysVersion};
    return await runCommand(command);
  }
}
