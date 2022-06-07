import 'dart:convert';

import 'package:logger/src/logger.dart';
import 'package:logger/src/log_printer.dart';
import 'package:logger/src/ansi_color.dart';

/// Outputs simple log messages:
/// ```
/// [E] Log message  ERROR: Error info
/// ```
class SimplePrinter extends LogPrinter {
  static final levelPrefixes = {
    Level.verbose: '[V]',
    Level.debug: '[D]',
    Level.info: '[I]',
    Level.warning: '[W]',
    Level.error: '[E]',
    Level.wtf: '[WTF]',
  };

  static final levelColors = {
    Level.verbose: AnsiColor.fg(AnsiColor.grey(0.5)),
    Level.debug: AnsiColor.none(),
    Level.info: AnsiColor.fg(12),
    Level.warning: AnsiColor.fg(208),
    Level.error: AnsiColor.fg(196),
    Level.wtf: AnsiColor.fg(199),
  };

  final bool printTime;
  final bool colors;
  final int stackTraceBeginIndex;

  SimplePrinter(
      {this.stackTraceBeginIndex = 0,
      this.printTime = false,
      this.colors = false});

  @override
  List<String> log(LogEvent event) {
    var messageStr = _stringifyMessage(event.message);
    var stackTraceStr = formatStackTrace(StackTrace.current);
    var errorStr = event.error != null ? '  ERROR: ${event.error}' : '';
    var timeStr = printTime ? '[${DateTime.now().toIso8601String()}]' : '';
    return [
      '${_labelFor(event.level)}$timeStr[$stackTraceStr]:$messageStr$errorStr'
    ];
  }

  String _labelFor(Level level) {
    var prefix = levelPrefixes[level]!;
    var color = levelColors[level]!;

    return colors ? color(prefix) : prefix;
  }

  String _stringifyMessage(dynamic message) {
    final finalMessage = message is Function ? message() : message;
    if (finalMessage is Map || finalMessage is Iterable) {
      var encoder = JsonEncoder.withIndent(null);
      return encoder.convert(finalMessage);
    } else {
      return finalMessage.toString();
    }
  }

  String? formatStackTrace(StackTrace? stackTrace) {
    var lines = stackTrace.toString().split('\n');
    var start = stackTraceBeginIndex + 4;
    if (start > 0 && start < lines.length - 1) {
      lines = lines.sublist(start, start + 1); //fix: too much trace ,reduce
    }
    
    var formatted = '${lines[0].replaceFirst(RegExp(r'#\d+\s+'), '')}';

    if (formatted.isEmpty) {
      return null;
    } else {
      return formatted;
    }
  }
}
