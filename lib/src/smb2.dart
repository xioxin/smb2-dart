import 'dart:async';
import 'dart:io';

import 'dart:math';

import 'dart:typed_data';

import 'package:smb2/src/structures/base.dart';
import 'package:smb2/src/structures/header.dart';
import 'package:smb2/src/structures/negotiate.dart';
import 'package:smb2/src/structures/read.dart';
import 'package:smb2/src/structures/session_setup.dart';
import 'package:smb2/src/structures/tree_connect.dart';
import 'package:smb2/src/tools/buffer.dart';
import 'package:smb2/src/tools/concurrent_queue.dart';
import 'package:smb2/src/tools/ms_erref.dart';

import 'structures/close.dart';
import 'structures/open.dart';
import 'tools/constant.dart';
import 'tools/ntlm/type2.dart';
import 'tools/smb_message.dart';

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
  int packetConcurrency = 20;

  Socket socket;

  int sessionId;
  int messageId = 0;
  int treeId;

  List<int> processId;

  bool isAsync = false;
  bool isMessageIdSetted = false;

  bool connected = false;

  List<int> nonce;
  String path = '';

  Type2Message type2Message;

  Map<String, Completer<SMBMessage>> responsesCompleter = {};

  List<int> responseBuffer = List();

  String get fullPath {
    String p = '\\\\';
    p += ip;
    p += '\\';
    if (path != null && path != '') {
      p += path;
    }
    return p;
  }

  SMB({
    this.path,
    this.ip,
    this.username,
    this.password,
    this.domain,
    this.port,
    this.debug,
    this.autoCloseTimeout,
    this.packetConcurrency,
  }) {
    this.domain ??= 'WORKGROUP';
  }

  Future connect() async {
    this.socket = await Socket.connect(this.ip, this.port ?? 445,
        timeout: Duration(seconds: 5));

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

    await request(Negotiate(), {});
    await request(SessionSetupStep1(), {});
    await request(SessionSetupStep2(), {});
    await request(TreeConnect(), {});
  }

  Future<SMBMessage> request(
      Structure structure, Map<String, dynamic> params) async {
    structure.connection = this;
    final mid = this.messageId++;

    final header = this.isAsync
        ? HeaderAsync(processId: this.processId, sessionId: this.sessionId)
        : HeaderSync(processId: this.processId, sessionId: this.sessionId);
    final headerData = Map<String, dynamic>();
    headerData.addAll(structure.headers);
    headerData['MessageId'] = mid;
    final buffer = header.getBuffer(headerData) + structure.getBuffer(params);
    final data = addNetBios(buffer);
    this.socket.add(data);
    return await getResponse(structure, mid);
  }

  Future<SMBMessage> getResponse(Structure structure, int messageId) async {
    final mid = messageId.toRadixString(16).padLeft(8, '0');
    Completer c = new Completer<SMBMessage>();
    responsesCompleter[mid] = c;
    SMBMessage msg = await c.future;

    msg = await structure.preProcessing(msg);
    if (structure.successCode == msg.status.code) {
      msg.setData(structure.parse(msg.buffer));
      structure.onSuccess(msg);
      return msg;
    }
    throw msg.status;
  }

  response(List<int> data) {
    responseBuffer.addAll(data);
    if (responseBuffer.length >= 4) {
      try {
        final msgLength = ByteData.view(Uint8List.fromList(responseBuffer).buffer,0, 4).getUint32(0, Endian.big);
        if (responseBuffer.length >= msgLength + 4) {
          final headerData = readHeaders(responseBuffer.sublist(4, 4 + HeaderLength));
          var mId = headerData["MessageId"].toRadixString(16).padLeft(8, '0');
          final buffer = responseBuffer.sublist(4 + HeaderLength, 4 + msgLength);
          final msg = SMBMessage(
              messageId: mId,
              header: headerData,
              buffer: buffer,
              status: getStatus(headerData['Status']));
          if (responsesCompleter[mId] != null) {
            responsesCompleter[mId].complete(msg);
            responsesCompleter[mId] = null;
          } else {
            throw "no find responsesCompleter MessigeId:${mId}";
          }
          if (responseBuffer.length > 4 + msgLength + HeaderLength) {
            this.responseBuffer = this.responseBuffer.sublist(4 + msgLength + HeaderLength, this.responseBuffer.length);
          } else {
            this.responseBuffer.clear();
          }
        }
      } catch(err) {
        print(data);
        throw err;
      }
    }
  }

  Map<String, dynamic> readHeaders(List<int> buffer) {
    final header = this.isAsync
        ? HeaderAsync(processId: this.processId, sessionId: this.sessionId)
        : HeaderSync(processId: this.processId, sessionId: this.sessionId);
    return header.parse(buffer);
  }

  List<int> addNetBios(List<int> buffer) {
    var netBios = ByteDataWriter(bufferLength: 4);
    netBios.writeInt8(0x00);
    netBios.writeInt8((0xff0000 & buffer.length) >> 16);
    netBios.writeInt16(0xffff & buffer.length);
    return netBios.toBytes().toList() + buffer;
  }

  Future<bool> exists(String path) async {
    var file;
    try {
      file = await open(path);
    } catch (err) {
      if (err is MsException) {
        if (err.code == 'STATUS_OBJECT_NAME_NOT_FOUND' ||
            err.code == 'STATUS_OBJECT_PATH_NOT_FOUND') {
          return false;
        }
      }
      throw err;
    }
    await close(file);
    return true;
  }

  close(SMBFile file) async {
    return await request(CloseFile(), {
      'fileId': file.fileId,
    });
  }

  rename() {}

  Future<List<int>> readFile(
    SMBFile file, {
    int length,
    int offset,
  }) async {
    length ??= file.fileLength;
    offset ??= 0;
    final start = offset;
    offset = 0;
    final List<int> result = List(length);

    final cq = ConcurrentQueue(5, () {
      if(offset >= length) return null;
      final packetOffset = start + offset;
      final resultOffset = offset;
      int packetSize = min(MAX_READ_LENGTH, length - offset);
      offset += packetSize;
      Completer c = new Completer();
      (() async {
//        print('packetOffset: $packetOffset, packetSize: $packetSize');
//        await Future.delayed(const Duration(seconds: 1));
        print('readFile');
        print({
          'fileId': file.fileId,
          'length': packetSize,
          'offset': packetOffset,
        });

        final msg = await request(ReadFile(), {
          'fileId': file.fileId,
          'length': packetSize,
          'offset': packetOffset,
        });

        final List<int> buf = msg.data['Buffer'];
        if(buf is List) {
          int i = 0;
          buf.forEach((v) => result[resultOffset + (i++)] = v);
        }
        c.complete();
      })();
      return c.future;
    });

    await cq.future;

    print('over');

    return result;
  }

  Future<SMBFile> open(String path, {int mask = FILE_OPEN}) async {
    final msg = await request(OpenFile(), {
      'path': path,
      'desiredAccess': mask,
    });

    final file = SMBFile.formMessage(msg);

    print(file);

    return file;
  }

  createReadStream() {}

  createWriteStream() {}

  writeFile() {}

  unlink() {}

  readdir() {}

  rmdir() {}

  mkdir() {}

  getSize() {}

  read() {}

  write() {}

  truncate() {}
}
