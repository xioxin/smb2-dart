import 'dart:async';
import 'dart:convert';

import 'package:smb2/smb2.dart';
import 'package:smb2/src/tools/concurrent_queue.dart';
import 'package:utf/utf.dart';

void main() async {

  final smb = SMB(ip: '10.10.10.3', username: 'admin', password: 'Zhaoxin110', path : 'comic');

  await smb.connect();

//  if(await smb.exists('index.php')) {
//    print('文件存在');
//  } else {
//    print('文件不存在');
//  }


  final file = await smb.open('index.php');
  final fileData = await smb.readFile(file);

  print(utf8.decode(fileData));

  await smb.close(file);


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


