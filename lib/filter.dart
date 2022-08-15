import 'dart:io';

import 'package:glob/glob.dart';
import 'package:yaml/yaml.dart';

class Filter {
  Filter(String text) {
    final YamlMap? map = loadYaml(text) as YamlMap?;
    includeList = _loadList(map, 'include', true);
    excludeList = _loadList(map, 'exclude');
  }

  late final List<Glob> includeList;
  late final List<Glob> excludeList;

  bool isExcluded(String path) {
    for (final Glob glob in includeList) {
      if (!glob.matches(path)) {
        return true;
      }
    }
    for (final Glob glob in excludeList) {
      if (glob.matches(path)) {
        return true;
      }
    }

    return false;
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
}
