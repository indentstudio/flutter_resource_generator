import 'dart:io';

import 'package:glob/glob.dart';
import 'package:yaml/yaml.dart';

class Options {
  Options(String text) {
    final YamlMap? map = loadYaml(text) as YamlMap?;
    _includeList = _loadList(map, 'include', true);
    _excludeList = _loadList(map, 'exclude');
    _renameList = _loadMap(map, 'replace');
  }

  late final List<Glob> _includeList;
  late final List<Glob> _excludeList;

  late final Map<RegExp, String> _renameList;

  bool isExcluded(String path) {
    if (_includeList.every((Glob glob) => !glob.matches(path))) {
      return true;
    }
    if (_excludeList.any((Glob glob) => glob.matches(path))) {
      return true;
    }
    return false;
  }

  String rename(String name) {
    String newName = name;
    _renameList.forEach((RegExp key, String value) {
      newName = newName.replaceAll(key, value);
    });
    return newName;
  }

  List<Glob> _loadList(YamlMap? map, String key,
      [bool emptyEqualsAll = false]) {
    try {
      final YamlList? list = map?[key] as YamlList?;
      if (emptyEqualsAll && (list == null || list.isEmpty)) {
        return <Glob>[Glob('**')];
      }
      if (list == null) {
        return <Glob>[];
      }
      return list.whereType<String>().map<Glob>((String e) => Glob(e)).toList();
    } catch (e, st) {
      print(e);
      print(st);
      exit(2);
    }
  }

  Map<RegExp, String> _loadMap(YamlMap? map, String key) {
    try {
      final YamlMap? list = map?[key] as YamlMap?;
      if (list == null || list.isEmpty) {
        return <RegExp, String>{};
      }
      return list.map<RegExp, String>((dynamic key, dynamic value) =>
          MapEntry<RegExp, String>(RegExp(key.toString()), value.toString()));
    } catch (e, st) {
      print(e);
      print(st);
      exit(2);
    }
  }
}
