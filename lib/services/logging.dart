import 'package:logger/logger.dart';

Function logger = (Type type) => Logger(
      printer: CustomerPrinter(type.toString()),
      level: Level.verbose,
    );

class CustomerPrinter extends LogPrinter {
  final String className;

  CustomerPrinter(this.className);

  @override
  List<String> log(LogEvent event) {
    final color = PrettyPrinter.levelColors[event.level]!;
    final emoji = PrettyPrinter.levelEmojis[event.level];
    final message = event.message;

    return [color('$emoji $className: $message')];
  }
}
