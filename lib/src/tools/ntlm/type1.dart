import 'dart:typed_data';
import 'dart:convert';
import '../buffer.dart';
import './common/utils.dart';
import './common/flags.dart' as flags;

/// Creates a type 1 NTLM message from the [domain] and [workstation]
List<int> createType1Message({String ntdomain = "", String hostname = ""}) {

  const BODY_LENGTH = 32;

  const signature = "NTLMSSP";

  ntdomain = ntdomain.toUpperCase();
  hostname = hostname.toUpperCase();

  ByteDataWriter buf = ByteDataWriter(bufferLength: BODY_LENGTH + ntdomain.length + hostname.length, endian: Endian.little);

  buf.write(ascii.encode(signature));
  buf.writeUint8(0);
  buf.writeUint8(0x01); // byte type;

  buf.writeUint8(0x00); // byte zero[3];
  buf.writeUint8(0x00); // byte zero[3];
  buf.writeUint8(0x00); // byte zero[3];

  buf.writeUint16(0xb203); // short flags;

  buf.writeUint8(0x00); // byte zero[2];
  buf.writeUint8(0x00); // byte zero[2];


  buf.writeUint16(ntdomain.length); // short dom_len;
  buf.writeUint16(ntdomain.length); // short dom_len;

  var ntdomainoff = 0x20 + ntdomain.length;
  buf.writeUint16(ntdomainoff); // short dom_off;

  buf.writeUint8(0x00); // byte zero[2];
  buf.writeUint8(0x00); // byte zero[2];


  buf.writeUint16(hostname.length); // short dom_len;
  buf.writeUint16(hostname.length); // short dom_len;

  buf.writeUint16(0x20); // short host_off;


  buf.writeUint8(0x00); // byte zero[2];
  buf.writeUint8(0x00); // byte zero[2];

  buf.write(ascii.encode(hostname));
  buf.write(ascii.encode(ntdomain));

  return buf.toBytes().toList();
}
