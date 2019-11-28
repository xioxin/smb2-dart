import 'dart:async';
import 'dart:io';

import 'dart:math';

import 'dart:typed_data';

import 'package:smb2/src/structures/base.dart';
import 'package:smb2/src/structures/header.dart';
import 'package:smb2/src/structures/negotiate.dart';
import 'package:smb2/src/structures/session_setup.dart';
import 'package:smb2/src/tools/buffer.dart';
import 'package:smb2/src/tools/ms_erref.dart';

import 'tools/smb_message.dart';

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
  List<int> processId;


  bool isAsync = false;
  bool isMessageIdSetted = false;

  bool connected = false;

  List<int> nonce;


  Map<String, Completer<SMBMessage>> responsesCompleter = {};

  ByteDataReader responseBuffer = ByteDataReader();

  SMB({
    this.ip, this.username, this.password, this.domain,
    this.port, this.debug, this.autoCloseTimeout, this.packetConcurrency,
  }) {
    this.domain ??= 'WORKGROUP';
  }

  Future connect() async {
    this.socket =
    await Socket.connect(this.ip, this.port ?? 445, timeout: Duration(seconds: 5));

    socket.listen(response);

    final random = Random();

    this.sessionId = 0;
    this.messageId = 0;

    this.processId = [
      random.nextInt(256) & 0xff,
      random.nextInt(256) & 0xff,
      random.nextInt(256) & 0xff,
      random.nextInt(256) & 0xfe
    ];
    print(processId);

    await request(Negotiate(), {});
//    print(test);
    await request(SessionSetupStep1(this), {});

  }

  Future<SMBMessage> request(Structure structure, Map<String, dynamic> params) async {
    final mid = this.messageId ++;

    print('\n\n\n ===================: ${mid} :=================== ');

    final header = this.isAsync ?
    HeaderAsync(processId: this.processId, sessionId: this.sessionId) :
    HeaderSync(processId: this.processId, sessionId: this.sessionId);

    final headerData = Map<String, dynamic>();
    headerData.addAll(structure.headers);
    headerData['MessageId'] = mid;

    final buffer = header.getBuffer(headerData) + structure.getBuffer(params);
    final data = addNetBios(buffer);
    print('socket add ${data.length}');
    print(data);

    this.socket.add(data);
    print('等待返回数据');
    return await getResponse(structure, mid);
  }

  Future<SMBMessage> getResponse(Structure structure, int messageId) async {
    final mid = messageId.toRadixString(16).padLeft(8, '0');
    print('注册 ${mid}');
    Completer c = new Completer<SMBMessage>();
    responsesCompleter[mid] = c;
    SMBMessage msg = await c.future;

    msg = await structure.preProcessing(msg);
    if(structure.successCode == msg.status.code) {
      msg.data = structure.parse(msg.buffer);
      structure.onSuccess(msg);
      return msg;
    }
    throw msg.status;
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
        
        if(responseBuffer.remainingLength >= msgLength) {
          extract = true;
          final headerData = readHeaders(responseBuffer.read(HeaderLength));
          var mId = headerData["MessageId"].toRadixString(16).padLeft(8, '0');

          final buffer = responseBuffer.read(msgLength - HeaderLength);

          final msg = SMBMessage(id: mId, header: headerData, buffer: buffer, status: getStatus(headerData['Status']));
          if (responsesCompleter[mId] != null) {
            responsesCompleter[mId].complete(msg);
            responsesCompleter[mId] = null;
          } else {
            throw "no find responsesCompleter MessigeId:${mId}";
          }

          if(this.responseBuffer.remainingLength > 0) {
            final oldResponseBuffer = this.responseBuffer;
            this.responseBuffer.add(oldResponseBuffer.read(oldResponseBuffer.remainingLength).toList());
          } else {
            this.responseBuffer = ByteDataReader();
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