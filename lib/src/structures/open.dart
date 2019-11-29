import 'package:utf/utf.dart';

import 'base.dart';


class Create extends Structure {
  @override
  Map<String, dynamic> get headers =>
      {
        'Command': 'CREATE',
        'TreeId': connection.treeId,
      };

  @override
  List<Field> request = [
    Field('StructureSize', 2, defaultValue: 57),
    Field('SecurityFlags', 1),
    Field('RequestedOplockLevel', 1),
    Field('ImpersonationLevel', 4, defaultValue: 0x00000002),
    Field('SmbCreateFlags', 8),
    Field('Reserved', 8),
    Field('DesiredAccess', 4, defaultValue: 0x00100081),
    Field('FileAttributes', 4, defaultValue: 0x00000000),
    Field('ShareAccess', 4, defaultValue: 0x00000007),
    Field('CreateDisposition', 4, defaultValue: 0x00000001 ), // todo: 枚举 constants.FILE_OPEN
    Field('CreateOptions', 4, defaultValue: 0x00000020),
    Field('NameOffset', 2),
    Field('NameLength', 2),
    Field('CreateContextsOffset', 4),
    Field('CreateContextsLength', 4),
    Field('Buffer', 0, dynamicLength: 'NameLength'),
    Field('Reserved2', 2, defaultValue: 0x4200),
    Field('CreateContexts', 0, dynamicLength: 'CreateContextsLength'),
  ];

  @override
  List<Field> response = [
    Field('StructureSize', 2),
    Field('OplockLevel', 1),
    Field('Flags', 1),
    Field('CreateAction', 4),
    Field('CreationTime', 8),
    Field('LastAccessTime', 8),
    Field('LastWriteTime', 8),
    Field('ChangeTime', 8),
    Field('AllocationSize', 8),
    Field('EndOfFile', 8),
    Field('FileAttributes', 4),
    Field('Reserved2', 4),
    Field('FileId', 16),
    Field('CreateContextsOffset', 4),
    Field('CreateContextsLength', 4),
    Field('Buffer', 0, dynamicLength: 'CreateContextsLength'),
  ];
}

class OpenFile extends Create {

  @override
  List<int> getBuffer([Map<String, dynamic> data]) {
    final buffer = encodeUtf16le(data['path']);
    return super.getBuffer({
      'Buffer': buffer,
      'NameOffset': 0x0078,
      'CreateContextsOffset': 0x007a + buffer.length,
      'DesiredAccess': data['desiredAccess'],
    });
  }

}
