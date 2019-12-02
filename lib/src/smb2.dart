import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'dart:math';

import 'dart:typed_data';

import 'package:smb2/src/structures/base.dart';
import 'package:smb2/src/structures/header.dart';
import 'package:smb2/src/structures/negotiate.dart';
import 'package:smb2/src/structures/query_directory.dart';
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

  Uri uri;
  String ip;
  int port;

  String domain;
  String username;
  String password;

  bool debug;

  // 自动断开时间
  Duration autoCloseTimeout;

  // 并发
  int packetConcurrency;

  Socket socket;

  int sessionId;
  int messageId = 0;
  int treeId;

  List<int> processId;

  bool isAsync = false;
  bool isMessageIdSetted = false;

  bool connectLock = false;
  bool connected = false;

  List<int> nonce;
  String smbPath = '';

  List<String> rootPath = [];

  Type2Message type2Message;

  Map<String, Completer<SMBMessage>> responsesCompleter = {};

  List<int> responseBuffer = [];

  String get fullPath {
    String p = '\\\\';
    p += ip;
    p += '\\';
    if (smbPath != null && smbPath != '') {
      p += smbPath;
    }
    return p;
  }

  SMB(Uri this.uri, {
    this.domain,
    this.debug,
    this.autoCloseTimeout,
    this.packetConcurrency,
  }) {
    if(uri.scheme != 'smb') {
      throw "Scheme not smb";
    }

    if(uri.pathSegments.length < 1) {
      throw "At least one path is required";
    }
    this.ip = uri.host;
    this.port = uri.hasPort ? uri.port : 445;
    final userInfo = uri.userInfo.split(':').toList();

    if(userInfo.length >= 1) {
      this.username = Uri.decodeComponent(userInfo[0]);
    }
    if(userInfo.length >= 2) {
      this.password = Uri.decodeComponent(userInfo[1]);
    }

    if(this.domain == null){
      if(userInfo.length >= 3) {
        this.domain = Uri.decodeComponent(userInfo[2]);
      }
    }
    this.domain ??= 'WORKGROUP';

    this.smbPath = uri.pathSegments.first;
    this.rootPath = uri.pathSegments.sublist(1);

    if(this.debug){
      print(this);
    }

    this.packetConcurrency ??= 20;
    this.autoCloseTimeout ??= Duration(milliseconds: 2000);
  }


  toString() {
    return "==== SMB ======================\n"
        "     URI: $uri \n"
        "      IP: $ip \n"
        "    port: $port \n"
        "  domain: $domain \n"
        "username: $username \n"
        "password: $password \n"
        "    path: $smbPath \n"
           "===============================";
  }

  Future connect() async {

    if(connectLock || connected) {
      throw "Cannot connect repeatedly";
    }

    this.connectLock = true;

    this.socket = await Socket.connect(this.ip, this.port ?? 445, timeout: Duration(seconds: 5));

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
    this.connectLock = false;
    this.connected = true;
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

    while(true) {
      if (responseBuffer.length >= 4) {
        try {
          final msgLength = ByteData.view(Uint8List.fromList(responseBuffer).buffer,0, 4).getUint32(0, Endian.big);
          if(msgLength == 0){
            print('msgLength Is 0');
          } else if (responseBuffer.length >= msgLength + 4) {
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
            this.responseBuffer.removeRange(0, 4 + msgLength);
          } else {
            return;
          }
        } catch(err) {
          throw err;
        }
      } else {
        return;
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

    await ConcurrentQueue(this.packetConcurrency, () {
      if(offset >= length) return null;
      final packetOffset = start + offset;
      final resultOffset = offset;
      int packetSize = min(MAX_READ_LENGTH, length - offset);
      offset += packetSize;
      return (() async {
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
      })();
    }).future;

    return result;
  }


  _parsePath(String path) {
    final u = Uri.parse(path);
    final List<String> pathSegments = [];
    pathSegments.addAll(this.rootPath);
    pathSegments.addAll(u.pathSegments);
    final p = Uri.parse(pathSegments.where((v) => v != '').join('/')).toFilePath(windows: true);;
    return p;
  }


  Future<SMBFile> open(String path, {int mask = FILE_OPEN}) async {
    path = _parsePath(path);
    final msg = await request(OpenFile(), {
      'path': path,
      'desiredAccess': mask,
    });
    final file = SMBFile.formMessage(msg);
    if(this.debug) {
      print(file);
    }
    return file;
  }

  createReadStream() {}

  createWriteStream() {}

  writeFile() {}

  unlink() {}

  Future<List<SMBFile>> readDirectory(String path, {String filter = '*'}) async {
    final file = await this.open(path);
    if(!file.isDirectory) {
      await close(file);
      throw "Not a Directory";
    }
    final msg = await request(QueryDirectory(), { 'fileId': file.fileId, 'filter': filter });
    final files = parseFiles(msg.data['Buffer']);
    await close(file);
    return files;
  }

  rmdir() {}

  mkdir() {}

  getSize() {}

  read() {}

  write() {}

  truncate() {}

  disconnect() {
    if (this.connected) {
      this.connected = false;
      this.responseBuffer.clear();
      this.responsesCompleter.clear();
      this.messageId = 0;
      this.socket.close();
    }
  }
}
