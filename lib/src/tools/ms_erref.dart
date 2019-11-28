part 'ms_erref.data.dart';


class MsStatusInfo {
  String code;
  String message;
  int value;
  MsStatusInfo({this.code, this.message, this.value});
}



class MsException implements Exception {

  final String code;
  final String message;
  final int value;
  final String valueHex;

  MsStatusInfo facility;
  MsStatusInfo severity;

  MsException({this.code, this.message, this.value, this.valueHex});

  @override
  String toString() => '$code ($valueHex) : $message';
}

MsException getStatus(int errorCode) {
  final hex = '0x' + errorCode.toRadixString(16).toUpperCase().padLeft(8, '0');

  Map<String, dynamic> ntErr = ntStatus[hex] ?? win32ErrorCodes[hex] ?? {
    'code': 'ERROR_UNRECOGNIZED',
    'message': 'Unrecognized error',
  };

  final err = MsException(code: ntErr['code'], message: ntErr['message'], value: errorCode, valueHex: hex);

  final facility = (errorCode >> 16) & 0x7ff;
  final facilityData = facilities[facility] ?? {
    'code': 'FACILITY_UNRECOGNIZED',
    'message': 'Unrecognized facility',
  };
  err.facility = MsStatusInfo(code: facilityData['code'], message: facilityData['message'], value: facility);

  final severity = (errorCode >> 30) & 0x03;
  final severityData = severities[severity] ?? {
    'code': 'STATUS_UNRECOGNIZED',
    'message': 'Unrecognized status',
  };
  err.severity = MsStatusInfo(code: severityData['code'], message: severityData['message'], value: severity);

  return err;
}

