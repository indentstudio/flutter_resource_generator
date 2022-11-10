import 'dart:io';

import 'package:path/path.dart';

import 'format.dart';
import 'logger.dart';
import 'options.dart';
import 'parser.dart';
import 'template.dart';

const String _generateLogPrefix = 'Generating resource records';

Logger logger = Logger();

class ResourceDartBuilder {
  ResourceDartBuilder(String projectRootPath, this.outputPath) {
    this.projectRootPath = projectRootPath.replaceAll('$separator.', '');

    final File yamlFile = File('$projectRootPath/resource_generator.yaml');
    if (yamlFile.existsSync()) {
      final String text = yamlFile.readAsStringSync();
      options = Options(text);
    }
  }

  Options? options;
  bool isPreview = true;

  void generateResourceDartFile(String className) {
    print('$_generateLogPrefix for project: $projectRootPath');
    final String pubYamlPath = '$projectRootPath${separator}pubspec.yaml';
    final ResourceDartParser parser =
        ResourceDartParser(projectRootPath, options);
    try {
      final List<FolderModel> model = parser.parse(pubYamlPath);
      _generateCode(className, model);
    } catch (e) {
      if (e is StackOverflowError && e.stackTrace != null) {
        writeText(e.stackTrace!);
      } else {
        writeText(e);
      }
    }
    print('$_generateLogPrefix finish.');
  }

  File get logFile => File('.dart_tool${separator}resource_generator_log.txt');

  late final String projectRootPath;
  late final String outputPath;

  /// Write logs to the file
  /// Defaults to `.dart_tools/resource_generator_log.txt`
  void writeText(Object text, {File? file}) {
    file ??= logFile;
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file
      ..writeAsStringSync(DateTime.now().toString(), mode: FileMode.append)
      ..writeAsStringSync('  : $text', mode: FileMode.append)
      ..writeAsStringSync('\n', mode: FileMode.append);
  }

  File? _resourceFile;

  File get resourceFile {
    if (File(outputPath).isAbsolute) {
      _resourceFile ??= File(outputPath);
    } else {
      _resourceFile ??= File('$projectRootPath$separator$outputPath');
    }

    _resourceFile!.createSync(recursive: true);
    return _resourceFile!;
  }

  /// Generate the dart code
  void _generateCode(String className, List<FolderModel> models) {
    writeText('Start writing records');
    resourceFile.deleteSync(recursive: true);
    resourceFile.createSync(recursive: true);

    final StringBuffer source = StringBuffer();
    final Template template = Template();
    source.write(template.license);
    source.write(template.classDeclare(className));
    for (final FolderModel model in models) {
      source.write(template.imageGroup(model.name));
    }
    source.write(template.classDeclareFooter);

    for (final FolderModel model in models) {
      source.write(template.classDeclare(model.name));
      for (final String imagePath in model.imagePaths) {
        final String relativePath = relative(imagePath, from: projectRootPath);
        source.write(
            template.imageAsset(imagePath, relativePath, isPreview, options));
      }
      source.write(template.classDeclareFooter);
    }

    final Stopwatch sw = Stopwatch();
    sw.start();
    final String formattedCode = formatFile(source.toString());
    sw.stop();
    print('Formatted records in ${sw.elapsedMilliseconds}ms');
    sw.reset();
    resourceFile.writeAsString(formattedCode);
    sw.stop();
    writeText('End writing records ${sw.elapsedMilliseconds}');
  }
}
