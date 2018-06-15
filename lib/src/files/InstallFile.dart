import 'dart:io';
import 'dart:async';

import 'files.dart';

import 'package:uuid/uuid.dart';

class InstallFile {
  static const String FILE_NAME = ".install";

  static String sID;

  static bool _justInstalled = false;
  get justInstalled => _justInstalled;

  static Future<String> id() async {
    if (sID != null) return sID;

    File installFile = await Files.get(FILE_NAME);

    try {
      var exists = await installFile.exists();

      if (!exists) {
        _justInstalled = true;

        sID = writeInstallationFile(installFile);
      } else {
        sID = await readInstallationFile(installFile);
      }
    } catch (ex) {
      sID = "";
    }

    return sID;
  }

  static Future<String> readInstallationFile(File installFile) async {
    File file = await Files.get(FILE_NAME);

    String content = await Files.readFile(file);

    return content;
  }

  static String writeInstallationFile(File file) {
    var uuid = new Uuid();

    // Generate a v4 (random) id
    var id = uuid.v4(); // -> '110ec58a-a0f2-4ac4-8393-c866d813b8d1'

    Files.writeFile(file, id);

    return id;
  }
}
