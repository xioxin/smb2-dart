import 'package:utf/utf.dart';

import 'base.dart';
import 'dart:convert';

class TreeConnect extends Structure {

  @override
  Map<String, dynamic> headers = {
    'Command': 'TREE_CONNECT',
  };

  @override
  String successCode = 'STATUS_SUCCESS';

  @override
  List<Field> request = [
    Field('StructureSize', 2, defaultValue: 9),
    Field('Reserved', 2),
    Field('PathOffset', 2, defaultValue: 72),
    Field('PathLength', 2),
    Field('Buffer', 0, dynamicLength: 'PathLength'),
  ];

  @override
  List<Field> response = [
    Field('StructureSize', 2),
    Field('ShareType', 1),
    Field('Reserved', 1),
    Field('ShareFlags', 4),
    Field('Capabilities', 4),
    Field('MaximalAccess', 4),
  ];

  @override
  List<int> getBuffer([Map<String, dynamic> _data ]) {
    Map<String, dynamic> data = {};
    if(data != null) data.addAll(_data);

    data['Buffer'] = encodeUtf16le(connection.fullPath);

    return super.getBuffer(data);
  }

  onSuccess(msg){
    connection.treeId = msg.header['TreeId'];
  }

}
