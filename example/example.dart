import 'dart:convert';
import 'dart:io';

import 'dart:math';

import 'dart:typed_data';

import 'package:smb2/smb2.dart';
import 'package:smb2/src/tools/buffer.dart';

void main() async {

  final smb = SMB(ip: '127.0.0.1');

  await smb.connect();



}


