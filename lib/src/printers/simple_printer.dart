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

  SimplePrinter(
      {this.stackTraceBeginIndex = 0,
      this.printTime = false,
      this.colors = false});

  @override
  List<String> log(LogEvent event) {
    var messageStr = _stringifyMessage(event.message);
    var stackTraceStr = formatStackTrace(
        Chain.current()); // Chain.forTrace(StackTrace.current);
    var errorStr = event.error != null ? '  ERROR: ${event.error}' : '';
    var timeStr = printTime ? '[${DateTime.now().toIso8601String()}]' : '';
    return [
      '$timeStr${_labelFor(event.level)}[$stackTraceStr]:$messageStr$errorStr'
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

  String? formatStackTrace(Chain chain) {
    // 将 core 和 flutter 包的堆栈合起来（即相关数据只剩其中一条）
    chain = chain.foldFrames((frame) => frame.isCore || frame.package == "flutter");
    // 取出所有信息帧
    final frames = chain.toTrace().frames;
    frames.forEach((element) {
      print(element.member);
    });
    // 找到当前函数的信息帧
    final idx = frames.indexWhere((element) => element.member == "Logger.log") + stackTraceBeginIndex;
    if (idx == -1 || idx + 1 >= frames.length) {
      return "";
    }
    // 调用当前函数的函数信息帧
    final frame = frames[idx + 1];
    return '${frame.location}';
  }
}
