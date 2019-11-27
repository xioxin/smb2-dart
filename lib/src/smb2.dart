import 'dart:async';
import 'dart:io';

import 'dart:math';

import 'dart:typed_data';

import 'package:smb2/src/structures/base.dart';
import 'package:smb2/src/structures/header.dart';
import 'package:smb2/src/structures/header_sync.dart';
import 'package:smb2/src/structures/negotiate.dart';
import 'package:smb2/src/tools/buffer.dart';

ZLibCodec zlib;


class SMB {

  String ip;
  String port;

  String domain;
  String username;
  String password;

  bool debug;

  // 自动断开时间
  int autoCloseTimeout;

  // 并发
  int packetConcurrency;

  Socket socket;

  int sessionId;
  int messageId = 0;
  int processId;


  bool isAsync = false;
  bool isMessageIdSetted = false;

  Map<String, Completer<List<int>>> responsesCompleter = {};

  ByteDataReader responseBuffer = ByteDataReader();

  SMB({
    this.ip, this.username, this.password, this.domain,
    this.port, this.debug, this.autoCloseTimeout, this.packetConcurrency,
  }) {
  }

  Future connect() async {
    this.socket =
    await Socket.connect(this.ip, this.port ?? 445, timeout: Duration(seconds: 5));

    socket.listen(response);

    final random = Random();

    this.sessionId = random.nextInt(256) & 0xff;
    this.messageId = 0;
    final processIdByteData = ByteData(4);
    processIdByteData.setUint8(0, random.nextInt(256) & 0xff);
    processIdByteData.setUint8(1, random.nextInt(256) & 0xff);
    processIdByteData.setUint8(2, random.nextInt(256) & 0xff);
    processIdByteData.setUint8(3, random.nextInt(256) & 0xfe);
    this.processId = processIdByteData.getUint32(0);
    print(processId);

    final test = await request(Negotiate(), {});
    print(test);

  }

  response(List<int> data) {
    print('response');
    print(data);
    responseBuffer.add(data);
    bool extract = true;
    while (extract) {
      extract = false;
      if(responseBuffer.remainingLength >= 4) {
        final msgLength = responseBuffer.readUint32(Endian.big);
        
        print('msgLength');
        print(msgLength);
        
        if(responseBuffer.remainingLength >= msgLength) {
          extract = true;
          final headerData = readHeaders(responseBuffer.read(HeaderLength));

          print(headerData);

          var mId = headerData["MessageId"].toRadixString(16).padLeft(8, '0');
          
          
          
          final buffer = responseBuffer.read(msgLength - HeaderLength);
          if (responsesCompleter[mId] != null) {
            responsesCompleter[mId].complete(buffer);
            responsesCompleter[mId] = null;
          } else {
            throw "no find responsesCompleter";
          }

          if(this.responseBuffer.remainingLength > 0) {
            final oldResponseBuffer = this.responseBuffer;
            this.responseBuffer = ByteDataReader();
            this.responseBuffer.add(oldResponseBuffer.read(oldResponseBuffer.remainingLength).toList());
          }
        }
      }
    }
  }


  Map<String, dynamic> readHeaders(List<int> buffer) {
    final header = this.isAsync ?
    HeaderAsync(processId: this.processId, sessionId: this.sessionId) :
    HeaderSync(processId: this.processId, sessionId: this.sessionId);
    return header.parse(buffer);
  }


  List<int> addNetBios(List<int> buffer) {
    var netBios = ByteDataWriter(bufferLength: 4);
    netBios.writeInt8(0x00);
    netBios.writeInt8((0xff0000 & buffer.length) >> 16);
    netBios.writeInt16(0xffff & buffer.length);
    return netBios.toBytes().toList() + buffer;
  }

  Future<Map<String, dynamic>> request(Structure structure, Map<String, dynamic> params) async {
    final mid = this.messageId ++;

    final header = this.isAsync ?
    HeaderAsync(processId: this.processId, sessionId: this.sessionId) :
    HeaderSync(processId: this.processId, sessionId: this.sessionId);

    final buffer = header.getBuffer() + structure.getBuffer(params);
    print(addNetBios(buffer));
    this.socket.add(addNetBios(buffer));
    print('getResponse');
    return await getResponse(structure, mid);
  }

  Future<Map<String, dynamic>> getResponse(Structure structure, int messageId) {
    final mid = messageId.toRadixString(16).padLeft(8, '0');
    Completer c = new Completer<List<int>>();
    responsesCompleter[mid] = c;
    return c.future.then((value) {
      return structure.parse(value);
    });
  }


  exists() {}

  rename() {}

  readFile() {}

  createReadStream() {}

  createWriteStream() {}

  writeFile() {}

  unlink() {}

  readdir() {}

  rmdir() {}

  mkdir() {}

  getSize() {}

  open() {}

  read() {}

  write() {}

  close() {}

  truncate() {}
}