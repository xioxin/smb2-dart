import 'base.dart';

class Negotiate extends Structure {

  @override
  Map<String, dynamic> headers = {
    'Command': 'NEGOTIATE',
  };

  @override
  String successCode = 'STATUS_SUCCESS';

  @override
  List<Field> request = [
    Field('StructureSize', 2, defaultValue: 36),
    Field('DialectCount', 2, defaultValue: 2),
    Field('SecurityMode', 2, defaultValue: 1),
    Field('Reserved', 2),
    Field('Capabilities', 4),
    Field('ClientGuid', 16),
    Field('ClientStartTime', 8),
    Field('Dialects', 4, defaultValue: 0x02021002),
  ];


  @override
  List<Field> response = [
    Field('StructureSize', 2),
    Field('SecurityMode', 2),
    Field('DialectRevision', 2),
    Field('Reserved', 2),
    Field('ServerGuid', 16),
    Field('Capabilities', 4),
    Field('MaxTransactSize', 4),
    Field('MaxReadSize', 4),
    Field('MaxWriteSize', 4),
    Field('SystemTime', 8),
    Field('ServerStartTime', 8),
    Field('SecurityBufferOffset', 2),
    Field('SecurityBufferLength', 2),
    Field('Reserved2', 4),
    Field('Buffer', 0, dynamicLength: 'SecurityBufferLength'),
  ];
}
