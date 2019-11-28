import 'package:smb2/src/tools/ms_erref.dart';

class SMBMessage {
  String id;
  Map<String, dynamic> header;
  List<int> buffer;

  Map<String, dynamic> data;

  MsException status;

  SMBMessage({this.id, this.header, this.buffer, this.status});
}