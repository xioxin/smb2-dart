import 'base.dart';

class Negotiate extends Structure {
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
  List<Field> response = [];
}
