Run Python code in Dart/Flutter and be happy forever and ever.

## Getting started

Calling `Flython.initialize()` causes the main Python app to be created, if it doesn't exist already.
Just follow the pattern of existing commands and create new ones.

Here is an example that shows how to subclass Flython and use OpenCV in Python to convert a colored image to grayscale:

```dart
import 'package:flython/flython.dart';

class OpenCV extends Flython {
  static const cmdToGray = 1;

  Future<dynamic> toGray(String inputFile,
      String outputFile,) async {
    var command = {
      "cmd": cmdToGray,
      "input": inputFile,
      "output": outputFile,
    };
    return await runCommand(command);
  }
}

```

You'll need to modify your `main.py` file to look like this:

```python
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
```

## An example project

Here is a very simple example project that uses Flython:

https://github.com/amahta/clipboard_ocr
