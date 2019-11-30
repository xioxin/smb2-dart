import 'package:utf/utf.dart';

import 'base.dart';

class CloseFile extends Structure {
  @override
  Map<String, dynamic> get headers => {
        'Command': 'CLOSE',
        'TreeId': connection.treeId,
      };

  @override
  List<Field> request = [
    Field('StructureSize', 2, defaultValue: 24),
    Field('Flags', 2),
    Field('Reserved', 4),
    Field('FileId', 16),
  ];

  @override
  List<Field> response = [
    Field('StructureSize', 2),
    Field('StructureSize', 2),
    Field('Flags', 2),
    Field('Reserved', 4),
    Field('CreationTime', 8),
    Field('LastAccessTime', 8),
    Field('LastWriteTime', 8),
    Field('ChangeTime', 8),
    Field('AllocationSize', 8),
    Field('EndofFile', 8),
//    Field('FileAttributes', 4),
  ];

  @override
  List<int> getBuffer([Map<String, dynamic> data]) {
    return super.getBuffer({
      'FileId': data['fileId'],
    });
  }
}
