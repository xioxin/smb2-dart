
import 'package:smb2/src/structures/base.dart';

class ReadFile extends Structure {
  @override
  Map<String, dynamic> get headers =>
      {
        'Command': 'READ',
        'TreeId': connection.treeId,
      };

  @override
  List<Field> request = [
    Field('StructureSize', 2,defaultValue: 49),
    Field('Padding', 1,defaultValue: 0x50),
    Field('Flags', 1),
    Field('Length', 4),
    Field('Offset', 8),
    Field('FileId', 16),
    Field('MinimumCount', 4),
    Field('Channel', 4),
    Field('RemainingBytes', 4),
    Field('ReadChannelInfoOffset', 2),
    Field('ReadChannelInfoLength', 2),
    Field('Buffer', 1),
  ];

  @override
  List<Field> response = [
    Field('StructureSize', 2),
    Field('DataOffset', 1),
    Field('Reserved', 1),
    Field('DataLength', 4),
    Field('DataRemaining', 4),
    Field('Reserved2', 4),
    Field('Buffer', 0, dynamicLength: 'DataLength'),
  ];


  @override
  List<int> getBuffer([Map<String, dynamic> data]) {
    // TODO: 数据检查
    return super.getBuffer({
      'FileId': data['fileId'],
      'Length': data['length'],
      'Offset': data['offset'],
    });
  }
}
