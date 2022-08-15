import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

import 'options.dart';

const List<String> platformExcludeFiles = <String>[
  // For MacOS
  '.DS_Store',
  // For Windows
  'thumbs.db',
  'desktop.ini',
];

class FolderModel {
  const FolderModel(this.name, this.imagePaths);

  final String name;
  final List<String> imagePaths;
}

class ResourceDartParser {
  ResourceDartParser(this.projectRootPath, this.filter);

  final String projectRootPath;
  final Options? filter;

  /// Creates parsed model
  List<FolderModel> parse(String yamlPath) {
    final List<FolderModel> retVal = <FolderModel>[];
    final List<String> assetPath = _getAssetPath(yamlPath);
    for (final String path in assetPath) {
      final String file = _getAbsolutePath(path);
      final FolderModel? model = _convertToModel(file);
      if (model != null) {
        retVal.add(model);
      }
    }
    return retVal;
  }

  /// Get asset paths from [yamlPath].
  List<String> _getAssetPath(String yamlPath) {
    final YamlMap map = loadYaml(File(yamlPath).readAsStringSync()) as YamlMap;
    final dynamic flutterMap = map['flutter'];
    if (flutterMap is YamlMap) {
      final dynamic assetMap = flutterMap['assets'];
      if (assetMap is YamlList) {
        return _getListFromYamlList(assetMap);
      }
    }
    return <String>[];
  }

  /// Get the asset from yaml list
  List<String> _getListFromYamlList(YamlList yamlList) {
    final List<String> list = <String>[];
    final List<String> r = yamlList.map((dynamic f) => f.toString()).toList();
    list.addAll(r);
    return list;
  }

  String _getAbsolutePath(String path) {
    if (isAbsolute(path)) {
      return path;
    }
    return join(projectRootPath, path);
  }

  FolderModel? _convertToModel(String filePath) {
    assert(FileSystemEntity.isDirectorySync(filePath));
    final String name = split(filePath).last;
    final List<String> images = <String>[];
    final Directory directory = Directory(filePath);
    final List<FileSystemEntity> entries = directory.listSync(
      recursive: false,
    );
    for (final FileSystemEntity entity in entries) {
      if (!FileSystemEntity.isFileSync(entity.path) ||
          platformExcludeFiles.contains(basename(entity.path)) ||
          (filter?.isExcluded(entity.path) ?? false)) {
        continue;
      }
      images.add(entity.path);
    }
    if (images.isEmpty) {
      return null;
    }
    return FolderModel(name, images);
  }
}
