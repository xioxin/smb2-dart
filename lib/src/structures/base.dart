import 'dart:typed_data';

import 'package:smb2/src/tools/buffer.dart';
import 'package:smb2/src/tools/smb_message.dart';

abstract class Structure {
  List<Field> request;
  List<Field> response;
  int fixedLength = 0;
  bool useTranslate = false;
  String successCode = 'STATUS_SUCCESS';


  static final protocolId = [
    0xfe,
    'S'.codeUnitAt(0),
    'M'.codeUnitAt(0),
    'B'.codeUnitAt(0)
  ];

  final Command = {
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

  Map<String, dynamic> headers = {};

  List<int> getBuffer([Map<String, dynamic> data ]) {
    data ??= Map<String, dynamic>();
    final buffer = ByteDataWriter(bufferLength: fixedLength > 0 ? fixedLength : 512);

    /* 设置动态长度 */
    request.forEach((r) {
      if(r.dynamicLength != null) {
        if(r.dynamicLength != '' && data[r.key] != null) {
          final v = data[r.key];
          if(v is List) {
            data[r.dynamicLength] = v.length;
          } else {
            print(r);
            throw '未实现4';
          }
        }
      }
    });

    print(data);

    request.forEach((r) {
      dynamic value = data != null ? data[r.key] : null;
      value ??= r.defaultValue ?? 0;

      if(r.translates != null) {
        final tv = r.translates[value];
        if (tv != null) {
          value = tv;
        }
      }

      if(useTranslate == true && Command[r.key] != null) {
        value = Command[r.key];
      };

      value ??= 0;


      if([1,2,4,8].contains(r.length) && value is int) {
        buffer.writeUint(r.length, value, Endian.little);
      }else {
        List<int> valueListInt;
        if(value is int) {
          valueListInt = [value];
        }else if(value is List<int>) {
          valueListInt = value;
        }

        if(valueListInt is List<int>){
          if(r.length == null || r.length == 0) {
            buffer.write(valueListInt);
          } else {
            final l = valueListInt.length;
            valueListInt.length = r.length;
            valueListInt.fillRange(l, valueListInt.length, 0);
            buffer.write(valueListInt);
          }
        }else {
          print(r);
          throw '未实现3';
        }
      }

    });
    return buffer.toBytes().toList();
  }

  Map<String, dynamic> parse(List<int> buffer) {
    if(response.length == 0) return {} as Map<String, dynamic>;
    final reader = ByteDataReader();
    reader.add(buffer);
    Map<String, dynamic> data = {};
    response.forEach((r) {
      var value;
      if(r.dynamicLength != null) {
        value = reader.read(data[r.dynamicLength]);
      }else if(r.length is int && [1,2,4,8].contains(r.length)) {
        value = reader.readUint(r.length, Endian.little);
      } else {
        value = reader.read(r.length);
      }
      if(r.translates != null) {
        final tv = r.translates.map((k, v) => MapEntry(v, k))[data[r.key]];
        if (tv!= null) {
          value = tv;
        }
      }
      data[r.key] = value;
    });

    return data;
  }


  Future<SMBMessage> preProcessing(SMBMessage msg) async {
    return msg;
  }

  onSuccess (SMBMessage msg) {
  }

}
class Field {
  String key;
  int length;
  dynamic defaultValue;
  Map<String, dynamic> translates;
  Field(this.key, this.length, {this.defaultValue, this.translates, this.dynamicLength});

  String dynamicLength;

  @override
  String toString() {
    return "key: ${key}, length:${length}, defaultValue: ${defaultValue}, translates: ${translates}, dynamicLength: ${dynamicLength}";
  }
}
