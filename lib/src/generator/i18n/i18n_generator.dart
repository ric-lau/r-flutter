import 'package:r_flutter/src/generator/i18n/i18n_generator_utils.dart';
import 'package:r_flutter/src/model/dart_class.dart';
import 'package:r_flutter/src/model/i18n.dart';

///
/// ```dart
/// class I18n {
///  final I18nLookup _lookup;
///
///  I18n(this._lookup);
///
///  static Locale? locale;
///
///  static Locale? get currentLocale => locale;
///
///  /// add custom locale lookup which will be called first
///  static I18nLookup customLookup;
///
///  static const I18nDelegate delegate = I18nDelegate();
///
///  static I18n of(BuildContext context) => Localizations.of<I18n>(context, I18n);
///
///  static List<Locale> get supportedLocales {
///    return const <Locale>[
///      Locale("en"),
///      Locale("de"),
///      Locale("pl"),
///      Locale("de", "AT")
///    ];
///  }
///
///  String get hello {
///    return customLookup?.hello ?? _lookup.hello;
///  }
///
///  String getString(String key, [Map<String, String> placeholders = const {}]) {
///    switch (key) {
///      case I18nKeys.hello:
///        return hello;
///    }
///    return "";
///  }
///}
/// ```
///
DartClass generateI18nClass(I18nLocales i18n) {
  final classString = StringBuffer("""class I18n {
  final I18nLookup _lookup;

  I18n(this._lookup);

  static Locale? locale;

  /// add custom locale lookup which will be called first
  static I18nLookup? customLookup;

  static const I18nDelegate delegate = I18nDelegate();

""");

  classString.writeln(_generateSupportedLocales(i18n));
  classString.write(_generateAccessorMethods(i18n));
  classString.write(_generateGetStringMethod(i18n));

  classString.writeln("}");
  return DartClass(code: classString.toString());
}

String _generateSupportedLocales(I18nLocales i18n) {
  final code =
  StringBuffer("""  static List<Locale> get supportedLocales {
    return const <Locale>[
""");

  final locales = i18n.locales
      .map((it) => it.locale)
      .where((it) => it != i18n.defaultLocale)
      .toList();

  code.write("      ${_generateLocaleInitialization(i18n.defaultLocale)}");
  for (final locale in locales) {
    code.write(",\n      ${_generateLocaleInitialization(locale)}");
  }
  code.write("\n");
  code.writeln("    ];");
  code.writeln("  }");
  return code.toString();
}

String _generateAccessorMethods(I18nLocales i18n) {
  final code = StringBuffer("");

  final values = i18n.defaultValues.strings;

  for (final value in values) {
    final methodCall = _stringValueMethodName(value);
    code.write(_genrateAccessorMethodComment(i18n, value));
    code.writeln(generateMethod(
        name: value.escapedKey,
        parameters: value.placeholders,
        code:
        "    return customLookup?.$methodCall ?? _lookup.$methodCall;"));
  }

  return code.toString();
}

String _genrateAccessorMethodComment(I18nLocales i18n, I18nString string) {
  final code = StringBuffer();
  code
    ..writeln("  ///")
    ..writeln("  /// <table style=\"width:100%\">")
    ..writeln("  ///   <tr>")
    ..writeln("  ///     <th>Locale</th>")
    ..writeln("  ///     <th>Translation</th>")
    ..writeln("  ///   </tr>");

  final locales = i18n.locales.toList()
    ..sort((item1, item2) =>
        item1.locale.toString().compareTo(item2.locale.toString()))
    ..remove(i18n.defaultValues)
    ..insert(0, i18n.defaultValues);

  for (final item in locales) {
    final localeString = item.locale.toString();
    final translation = item.strings
        .firstWhere((it) => it.key == string.key, orElse: () => null);

    code
      ..writeln("  ///   <tr>")
      ..writeln("  ///     <td style=\"width:60px;\">$localeString</td>");

    if (translation == null) {
      code.writeln("  ///     <td><font color=\"yellow\">⚠</font></td>");
    } else {
      code.writeln(
          "  ///     <td>\"${escapeStringLiteral(translation.value)}\"</td>");
    }
    code.writeln("  ///   </tr>");
  }
  code.writeln("  ///  </table>");
  code.writeln("  ///");
  return code.toString();
}

String _stringValueMethodName(I18nString value) {
  if (value.placeholders.isEmpty) {
    return value.escapedKey;
  } else {
    return "${value.escapedKey}(${value.placeholders.join(", ")})";
  }
}

String _generateGetStringMethod(I18nLocales i18n) {
  final code = StringBuffer();
  code
    ..writeln(
        "  String? getString(String key, [Map<String, String> placeholders = const {}]) {")
    ..writeln("    switch (key) {");

  final values = i18n.defaultValues.strings;

  final methodName = StringBuffer();
  for (final value in values) {
    methodName.clear();
    if (value.placeholders.isEmpty) {
      methodName.write(value.escapedKey);
    } else {
      methodName.write("${value.escapedKey}(");
      var isFirstPlaceholder = true;
      for (final placeholder in value.placeholders) {
        if (!isFirstPlaceholder) {
          methodName.write(", ");
        }
        isFirstPlaceholder = false;
        methodName.write("placeholders[\"$placeholder\"]!");
      }
      methodName.write(")");
    }

    code
      ..writeln("      case I18nKeys.${value.escapedKey}:")
      ..writeln("        return $methodName;");
  }

  code..writeln("    }")..writeln("    return '';")..writeln("  }");
  return code.toString();
}

String _generateLocaleInitialization(Locale locale) {
  if (locale.countryCode == null && locale.scriptCode == null) {
    return "Locale(\"${locale.languageCode}\")";
  }
  if (locale.scriptCode == null) {
    return "Locale(\"${locale.languageCode}\", \"${locale.countryCode}\")";
  }
  if (locale.countryCode == null) {
    return "Locale.fromSubtags(languageCode: \"${locale.languageCode}\", scriptCode: \"${locale.scriptCode}\")";
  }
  return "Locale.fromSubtags(languageCode: \"${locale.languageCode}\", scriptCode: \"${locale.scriptCode}\", countryCode: \"${locale.countryCode}\")";
}
