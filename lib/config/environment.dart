import 'dart:io';

class Environment {
  Environment._(this._values);

  factory Environment.current({String path = '.env'}) {
    return Environment._(<String, String>{
      ..._readDotEnv(path),
      ...Platform.environment,
    });
  }

  final Map<String, String> _values;

  String? get(String key) {
    final value = _values[key]?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  bool getBool(String key, {bool defaultValue = false}) {
    final value = get(key)?.toLowerCase();
    if (value == null) {
      return defaultValue;
    }

    return value == 'true' || value == '1' || value == 'yes';
  }

  static Map<String, String> _readDotEnv(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return const <String, String>{};
    }

    final values = <String, String>{};
    for (final rawLine in file.readAsLinesSync()) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      final equalsIndex = line.indexOf('=');
      if (equalsIndex <= 0) {
        continue;
      }

      final key = line.substring(0, equalsIndex).trim();
      final value = line.substring(equalsIndex + 1).trim();
      values[key] = _unquote(value);
    }

    return values;
  }

  static String _unquote(String value) {
    if (value.length < 2) {
      return value;
    }

    final first = value[0];
    final last = value[value.length - 1];
    if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
      return value.substring(1, value.length - 1);
    }

    return value;
  }
}
