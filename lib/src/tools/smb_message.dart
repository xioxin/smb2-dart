import 'package:smb2/src/tools/ms_erref.dart';
import 'package:smb2/src/tools/tools.dart';

import 'constant.dart';

class SMBMessage {
  String messageId;
  Map<String, dynamic> header;
  List<int> buffer;

  Map<String, dynamic> data;

  MsException status;

  SMBMessage({this.messageId, this.header, this.buffer, this.status});

  setData(Map<String, dynamic> data) {
    this.data = data;
  }
}

//
//class SMBFile extends SMBMessage {
//  SMBFile.formMessage(SMBMessage msg) {
//    this.messageId = msg.messageId;
//    this.header = msg.header;
//    this.buffer = msg.buffer;
//    this.status = msg.status;
//    this.setData(msg.data);
//  }
//
//  List<int> fileId;
//
//  DateTime creationTime;
//  DateTime lastAccessTime;
//  DateTime lastWriteTime;
//  DateTime changeTime;
//  int fileLength;
//
//
//  @override
//  setData(Map<String, dynamic> data) {
//    this.fileId = data['FileId'];
//    this.creationTime = fileTimeToDateTime(data['CreationTime']);
//    this.lastAccessTime = fileTimeToDateTime(data['LastAccessTime']);
//    this.lastWriteTime = fileTimeToDateTime(data['LastWriteTime']);
//    this.changeTime = fileTimeToDateTime(data['ChangeTime']);
//    this.changeTime = fileTimeToDateTime(data['FileAttributes']);
//    this.fileLength = data['EndOfFile'];
//    return super.setData(data);
//  }
//
//
//  @override
//  String toString() {
//    return
//      "        fileId: $fileId \n"
//      "    fileLength: $fileLength \n"
//      "  creationTime: $creationTime \n"
//      "lastAccessTime: $lastAccessTime \n"
//      " lastWriteTime: $lastWriteTime \n"
//      "    changeTime: $changeTime \n"
//      "     messageId: $messageId "
//    ;
//  }
//}

class SMBFile {
  SMBMessage msg;
  int index;
  DateTime creationTime;
  DateTime lastAccessTime;
  DateTime lastWriteTime;
  DateTime changeTime;
  int endOfFile;
  int allocationSize;
  int fileAttributes;
  int filenameLength;
  int eaSize;
  int shortNameLength;
  List<int> fileId;
  String shortName;
  String fileName;

  SMBFile({
    this.index,
    this.creationTime,
    this.lastAccessTime,
    this.lastWriteTime,
    this.changeTime,
    this.endOfFile,
    this.allocationSize,
    this.fileAttributes,
    this.filenameLength,
    this.eaSize,
    this.shortNameLength,
    this.fileId,
    this.shortName,
    this.fileName,
  });

  get fileLength => endOfFile;

  _fileAttributesIs(int v) => fileAttributes & v == v;

  get isDirectory => _fileAttributesIs(ATTR_DIRECTORY);

  get isFile => !isDirectory;

  get isHidden => _fileAttributesIs(ATTR_HIDDEN);

  get isReadonly => _fileAttributesIs(ATTR_READONLY);

  get isSystemFile => _fileAttributesIs(ATTR_SYSTEM);

  SMBFile.formMessage(SMBMessage msg) {
    this.msg = msg;
    this.fileId = msg.data['FileId'];
    this.creationTime = fileTimeToDateTime(msg.data['CreationTime']);
    this.lastAccessTime = fileTimeToDateTime(msg.data['LastAccessTime']);
    this.lastWriteTime = fileTimeToDateTime(msg.data['LastWriteTime']);
    this.changeTime = fileTimeToDateTime(msg.data['ChangeTime']);
    this.fileAttributes = msg.data['FileAttributes'];
    this.endOfFile = msg.data['EndOfFile'];
  }

  @override
  String toString() {
    return "SMBFile<${isFile ? 'F' : ''}${isDirectory ? 'D' : ''}${isHidden ? 'H' : ''}${isReadonly ? 'R' : ''}${isSystemFile ? 'S' : ''}:$fileName>";
  }
}
