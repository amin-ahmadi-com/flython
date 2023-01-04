import 'package:flython/flython.dart';

void main() async {
  final flython = Flython();
  await flython.initialize("python", "./main.py", false);
  print(await flython.sysVersion());
  flython.finalize();
}
