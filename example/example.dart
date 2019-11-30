import 'dart:async';
import 'dart:convert';

import 'package:smb2/smb2.dart';
import 'package:smb2/src/tools/concurrent_queue.dart';
import 'package:utf/utf.dart';

void main() async {

  final smb = SMB(ip: '10.10.10.3', username: 'admin', password: 'Zhaoxin110', path : 'comic');

  await smb.connect();


  await smb.connect();
  final file = await smb.open('LOL\\[LOL] Shiritsu Nikubenki Senmon Gakuen -Kikaika- [Chinese] [贝尔西行寺个人汉化].zip');

  await smb.readFile(file);
  print('erad end');

  smb.close(file);


//  if(await smb.exists('index.php')) {
//    print('文件存在');
//  } else {
//    print('文件不存在');
//  }


//  final file = await smb.open('LOL\\[LOL] Shiritsu Nikubenki Senmon Gakuen -Kikaika-  [chinese].zip');
//  final fileData = await smb.readFile(file);
//  print(utf8.decode(fileData));
//  await smb.close(file);

// final files = await smb.readDirectory('LOL');
//
// print(files);

//
//  int n = 0;
//
//  final cq = ConcurrentQueue(5, () {
//    n++;
//    if(n > 10) return null;
//    Completer c = new Completer();
//    (() async {
//      print('aaa');
//      await Future.delayed(const Duration(seconds: 1));
//      c.complete();
//    })();
//    return c.future;
//  });
//
//  await cq.future;
//
//  print('over');

}


