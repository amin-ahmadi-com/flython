import 'package:flython/flython.dart';

class OpenCV extends Flython {
  static const cmdToGray = 1;

  Future<dynamic> toGray(
    String inputFile,
    String outputFile,
  ) async {
    var command = {
      "cmd": cmdToGray,
      "input": inputFile,
      "output": outputFile,
    };
    return await runCommand(command);
  }
}

void main() async {
  final opencv = OpenCV();
  await opencv.initialize("python", "./example/opencv.py", false);
  await opencv.toGray("./image.png", "./image_gray.png");
  opencv.finalize();
}

// For the record, here are the contents of ./example/opencv.py, since it doesn't show up in the official package Example page on pub.dev (at least at the time of publishing this package)
/*
import argparse
import json
import sys

import cv2

CMD_SYS_VERSION = 0
CMD_TO_GRAY = 1


def run(command):
    if command["cmd"] == CMD_SYS_VERSION:
        return {
            "sys.version": sys.version,
        }

    if command["cmd"] == CMD_TO_GRAY:
        image = cv2.imread(command["input"])
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        cv2.imwrite(command["output"], gray)
        return {}

    else:
        return {"error": "Unknown command."}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--uuid")
    args = parser.parse_args()
    stream_start = f"`S`T`R`E`A`M`{args.uuid}`S`T`A`R`T`"
    stream_end = f"`S`T`R`E`A`M`{args.uuid}`E`N`D`"
    while True:
        cmd = input()
        cmd = json.loads(cmd)
        try:
            result = run(cmd)
        except Exception as e:
            result = {"exception": e.__str__()}
        result = json.dumps(result)
        print(stream_start + result + stream_end)
 */