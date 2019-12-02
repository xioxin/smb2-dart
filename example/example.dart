import 'package:smb2/smb2.dart';

void main() async {
  final uri = Uri.parse('smb://admin:Zhaoxin110@10.10.10.3/download/');
  final smb = SMB(uri, debug: true);
  await smb.connect();
  final files = await smb.readDirectory('COSH-023');
  print(files);

  smb.disconnect();
}


