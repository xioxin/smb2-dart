import 'package:smb2/smb2.dart';

void main() async {

  final smb = SMB(ip: '10.10.10.3', username: 'admin', password: 'Zhaoxin110', path : 'comic');

  await smb.connect();

  if(await smb.exists('index.php')) {
    print('文件存在');
  } else {
    print('文件不存在');
  }

}


