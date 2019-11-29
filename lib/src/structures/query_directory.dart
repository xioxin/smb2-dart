
import 'dart:typed_data';

import 'package:smb2/src/structures/base.dart';
import 'package:smb2/src/tools/buffer.dart';
import 'package:smb2/src/tools/tools.dart';
import 'package:utf/utf.dart';

class QueryDirectory extends Structure {
  @override
  Map<String, dynamic> get headers =>
      {
        'Command': 'QUERY_DIRECTORY',
        'TreeId': connection.treeId,
      };

  @override
  List<Field> request = [
    Field('StructureSize', 2, defaultValue: 33),
    Field('FileInformationClass', 1, defaultValue: 0x25),
    Field('Flags', 1),
    Field('FileIndex', 4),
    Field('FileId', 16),
    Field('FileNameOffset', 2,defaultValue:  96),
    Field('FileNameLength', 2),
    Field('OutputBufferLength', 4, defaultValue:  0x00010000),
    Field('Buffer', 0, dynamicLength: 'FileNameLength'),
  ];

  @override
  List<Field> response = [
    Field('StructureSize', 2),
    Field('OutputBufferOffset', 2),
    Field('OutputBufferLength', 4),
    Field('Buffer', 0, dynamicLength: 'OutputBufferLength'),
  ];

  @override
  List<int> getBuffer([Map<String, dynamic> data]) {
    // TODO: 数据检查
    final buffer = encodeUtf16le(data['filter'] ?? '*');
    return super.getBuffer({
      'FileId': data['fileId'],
      'Buffer': buffer,
    });
  }

}


parseFiles (List<int> buffer) {
  final reader = ByteData.view(Uint8List.fromList(buffer).buffer);
  final files = [];
  var offset = 0;
  var nextFileOffset = -1;
  while (nextFileOffset != 0) {
    // extract next file offset
    nextFileOffset = reader.getUint32(offset, Endian.little) ;
    // extract the file

    print('bufferL: ${buffer.length}, offset: $offset, nextFileOffset: $nextFileOffset');
    print('s: ${offset + 4}, e: ${nextFileOffset == 0 ? offset + nextFileOffset : buffer.length}');

    files.add(
        parseFile(
            buffer.sublist(
                offset + 4,
                nextFileOffset != 0 ? offset + nextFileOffset : buffer.length
            )
        )
    );
    // move to nex file
    offset += nextFileOffset;
  }
  return files;

}

class SMBFileInfo {
  int index;
  DateTime creationTime;
  DateTime lastAccessTime;
  DateTime lastWriteTime;
  DateTime changeTime;
  int endOfFile;
  int allocationSize;
  int fileAttributes;
  int filenameLength;
  int eaSize;
  int shortNameLength;
  List<int> fileId;

  String shortName;
  String fileName;

  SMBFileInfo();

  @override
  String toString() {
    return "SMBFileInfo<$fileName>";
  }
}

parseFile(List<int> buffer) {
  print(buffer);
  final reader = ByteDataReader(endian: Endian.little);
  reader.add(buffer);
  var file = SMBFileInfo();
  file.index = reader.readUint(4);
  file.creationTime = fileTimeToDateTime(reader.readUint(8));
  file.lastAccessTime = fileTimeToDateTime(reader.readUint(8));
  file.lastWriteTime = fileTimeToDateTime(reader.readUint(8));
  file.changeTime = fileTimeToDateTime(reader.readUint(8));
  file.endOfFile = reader.readUint(8);
  file.allocationSize = reader.readUint(8);
  file.fileAttributes = reader.readUint(4);
  file.filenameLength = reader.readUint(4);
  file.eaSize = reader.readUint(4);
  file.shortNameLength = reader.readUint(1);
  reader.skip(1);
  file.shortName = decodeUtf16le(reader.read(file.shortNameLength));
  reader.skip(24 - file.shortNameLength);
  reader.skip(2);
  file.fileId = reader.read(8);
  file.fileName = decodeUtf16le(reader.read(file.filenameLength));
  return file;
}