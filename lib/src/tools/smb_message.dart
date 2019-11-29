import 'package:smb2/src/tools/ms_erref.dart';
import 'package:smb2/src/tools/tools.dart';

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



class SMBFile extends SMBMessage {
  SMBFile.formMessage(SMBMessage msg) {
    this.messageId = msg.messageId;
    this.header = msg.header;
    this.buffer = msg.buffer;
    this.status = msg.status;
    this.setData(msg.data);
  }

  List<int> fileId;

  DateTime creationTime;
  DateTime lastAccessTime;
  DateTime lastWriteTime;
  DateTime changeTime;
  int fileLength;


  @override
  setData(Map<String, dynamic> data) {
    this.fileId = data['FileId'];
    this.creationTime = fileTimeToDateTime(data['CreationTime']);
    this.lastAccessTime = fileTimeToDateTime(data['LastAccessTime']);
    this.lastWriteTime = fileTimeToDateTime(data['LastWriteTime']);
    this.changeTime = fileTimeToDateTime(data['ChangeTime']);
    this.fileLength = data['EndOfFile'];
    return super.setData(data);
  }


  @override
  String toString() {
    return
      "        fileId: $fileId \n"
      "    fileLength: $fileLength \n"
      "  creationTime: $creationTime \n"
      "lastAccessTime: $lastAccessTime \n"
      " lastWriteTime: $lastWriteTime \n"
      "    changeTime: $changeTime \n"
      "     messageId: $messageId "
    ;
  }
}



