import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:logger/src/log_printer.dart';
import 'package:logger/src/logger.dart';
import 'package:logger/src/log_output.dart';

/// Writes the log output to a file.
class FileOutput extends LogOutput {
  final File file;
  final bool overrideExisting;
  final Encoding encoding;
  IOSink? _sink;
  
  @override
  LogPrinter? logPrinter;

  FileOutput({
      required this.file,
      this.logPrinter,
      this.overrideExisting = false,
      this.encoding = utf8
      });

  @override
  void init() {
    _sink = file.openWrite(
      mode: overrideExisting ? FileMode.writeOnly : FileMode.writeOnlyAppend,
      encoding: encoding,
    );
  }

  @override
  void output(OutputEvent event) {
    _sink?.writeAll(event.lines, '\n');
    _sink?.writeln();
  }

  @override
  void destroy() async {
    await _sink?.flush();
    await _sink?.close();
  }
}
