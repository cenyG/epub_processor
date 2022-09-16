import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;


Future<String> getFileChecksum(File file) async {
  final fileLength = await file.length();
  final hash = await file.openRead().transform(crypto.sha256).first;

  return '$hash:$fileLength';
}