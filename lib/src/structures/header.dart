
import 'base.dart';

const HeaderLength = 64;

const HeaderTranslateCommand = {
  'NEGOTIATE': 0x0000,
  'SESSION_SETUP': 0x0001,
  'LOGOFF': 0x0002,
  'TREE_CONNECT': 0x0003,
  'TREE_DISCONNECT': 0x0004,
  'CREATE': 0x0005,
  'CLOSE': 0x0006,
  'FLUSH': 0x0007,
  'READ': 0x0008,
  'WRITE': 0x0009,
  'LOCK': 0x000a,
  'IOCTL': 0x000b,
  'CANCEL': 0x000c,
  'ECHO': 0x000d,
  'QUERY_DIRECTORY': 0x000e,
  'CHANGE_NOTIFY': 0x000f,
  'QUERY_INFO': 0x0010,
  'SET_INFO': 0x0011,
  'OPLOCK_BREAK': 0x0012,
};


class HeaderSync extends Structure {
  final List<int> processId;
  final int sessionId;
  bool useTranslate = true;
  int fixedLength = HeaderLength;

  @override
  List<Field> get request => [
    Field('ProtocolId', 4, defaultValue: Structure.protocolId),
    Field('StructureSize', 2, defaultValue: HeaderLength),
    Field('CreditCharge', 2),
    Field('Status', 4),
    Field('Command', 2, translates: HeaderTranslateCommand),
    Field('Credit', 2, defaultValue: 126),
    Field('Flags', 4),
    Field('NextCommand', 4),
    Field('MessageId', 4),
    Field('MessageIdHigh', 4),
    Field('ProcessId', 4, defaultValue: processId),
    Field('TreeId', 4),
    Field('SessionId', 8, defaultValue: sessionId),
    Field('Signature', 16),
  ];

  @override
  List<Field> get response => request;

  HeaderSync({
    this.processId,
    this.sessionId,
  });
}

class HeaderAsync extends Structure {
  final List<int> processId;
  final int sessionId;
  bool useTranslate = true;
  int fixedLength = HeaderLength;

  @override
  List<Field> get request => [
    Field('ProtocolId', 4, defaultValue: Structure.protocolId),
    Field('StructureSize', 2, defaultValue: HeaderLength),
    Field('CreditCharge', 2),
    Field('Status', 4),
    Field('Command', 2, translates: HeaderTranslateCommand),
    Field('Credit', 2, defaultValue: 126),
    Field('Flags', 4),
    Field('NextCommand', 4),
    Field('MessageId', 4),
    Field('MessageIdHigh', 4),
    Field('AsyncId', 8),
    Field('SessionId', 8, defaultValue: sessionId),
    Field('Signature', 16),
  ];

  @override
  List<Field> get response => request;
  HeaderAsync({
    this.processId,
    this.sessionId,
  });
}
//头  ProtocolId     | size  | cred | status     | comma | Credit | Flags      | NextCommand| MessageId  | MsgIdHigh  | ProcessId          | TreeId      | SessionId                | Signature                                      | data ->
//原 254, 83, 77, 66,| 64, 0,| 0, 0,| 0, 0, 0, 0,| 1, 0, | 126, 0,| 0, 0, 0, 0,| 0, 0, 0, 0,| 1, 0, 0, 0,| 0, 0, 0, 0,| 114, 235, 192, 212,| 0, 0, 0, 0, |   0, 0, 0, 0, 0, 0, 0, 0,| 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,| 25, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 88, 0, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 78, 84, 76, 77, 83, 83, 80, 0, 1, 0, 0, 0, 3, 178, 0, 0, 9, 0, 9, 0, 41, 0, 0, 0, 9, 0, 9, 0, 32, 0, 0, 0, 49, 50, 55, 46, 48, 46, 48, 46, 49, 87, 79, 82, 75, 71, 82, 79, 85, 80
//我 254, 83, 77, 66,| 64, 0,| 0, 0,| 0, 0, 0, 0,| 0, 0, | 126, 0,| 0, 0, 0, 0,| 0, 0, 0, 0,| 0, 0, 0, 0,| 0, 0, 0, 0,| 207, 139, 169, 4,  | 0, 0, 0, 0, | 135, 0, 0, 0, 0, 0, 0, 0,| 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,| 25, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 88, 0, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 78, 84, 76, 77, 83, 83, 80, 0, 1, 0, 0, 0, 3, 178, 0, 0, 9, 0, 9, 0, 41, 0, 0, 0, 9, 0, 9, 0, 32, 0, 0, 0, 49, 50, 55, 46, 48, 46, 48, 46, 49, 87, 79, 82, 75, 71, 82, 79, 85, 80
//我 254, 83, 77, 66,| 64, 0,| 0, 0,| 0, 0, 0, 0,| 1, 0, | 126, 0,| 0, 0, 0, 0,| 0, 0, 0, 0,| 1, 0, 0, 0,| 0, 0, 0, 0,| 178, 94, 14, 214,  | 0, 0, 0, 0, | 144, 0, 0, 0, 0, 0, 0, 0,| 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,| 25, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 88, 0, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 78, 84, 76, 77, 83, 83, 80, 0, 1, 0, 0, 0, 3, 178, 0, 0, 9, 0, 9, 0, 41, 0, 0, 0, 9, 0, 9, 0, 32, 0, 0, 0, 49, 50, 55, 46, 48, 46, 48, 46, 49, 87, 79, 82, 75, 71, 82, 79, 85, 80


