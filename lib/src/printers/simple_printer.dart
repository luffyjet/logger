import 'dart:convert';

import 'package:logger/src/logger.dart';
import 'package:logger/src/log_printer.dart';
import 'package:logger/src/ansi_color.dart';
import 'package:stack_trace/stack_trace.dart';

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
  final int errorMethodCount;

  SimplePrinter(
      {this.stackTraceBeginIndex = 0,
      this.errorMethodCount = 8,
      this.printTime = true,
      this.colors = true});

  @override
  List<String> log(LogEvent event) {
    var messageStr = _stringifyMessage(event.message);
    var chan;
    var stackTraceStr;
    if(event.stackTrace != null){
      stackTraceStr = event.stackTrace.toString();
    }else{
      chan = Chain.current();
      stackTraceStr = formatStackTrace(chan, 1);
    }

    var errorStr = event.error != null ? '${event.error}' : '';
    var timeStr = printTime ? '${DateTime.now().toIso8601String()}' : '';
    return [
      '$timeStr ${_labelFor(event.level)}:$messageStr$errorStr \nStackTrace:\n$stackTraceStr'
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

  String? formatStackTrace(Chain chain, methodCount) {
    chain =
        chain.foldFrames((frame) => frame.isCore || frame.package == "flutter");
    // 取出所有信息帧
    var frames = chain.toTrace().frames;

    // 找到当前函数的信息帧
    final idx = frames.lastIndexWhere((element) => element.member == "Logger.log") +1+ stackTraceBeginIndex;
    if (idx == -1 || idx + 1 >= frames.length) {
      return "";
    }

    if (idx > 0 && idx < frames.length) {
      frames = frames.sublist(idx);
    }

    var formatted = <String>[];
    var count = 0;
    for (var line in frames) {
      formatted
          .add('${line.location.replaceFirst(RegExp(r'#\d+\s+'), '')}');
      if (++count == methodCount) {
        break;
      }
    }

    if (formatted.isEmpty) {
      return null;
    } else {
      return formatted.join('\n');
    }
  }
}
