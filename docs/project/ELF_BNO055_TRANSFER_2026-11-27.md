# ELF BNO055 code transfer

Source: `elf@192.168.2.23`, hostname `elf2-desktop`, ELF 2 Board, ARM64, Ubuntu22.04.5, kernel5.10.209. Original folder: `/home/elf/bno055`.

Destination: `jiaanguo@192.168.2.191`, hostname `QaQ`, x86_64. Transfer folder: `/home/jiaanguo/Workspace/elf-bno055-transfer-20261127`; portable archive beside it: `/home/jiaanguo/Workspace/elf-bno055-transfer-20261127.tar.gz`.

## Contents

`original/` preserves all8 original files byte for byte: three C++ programs, their three ARM64 binaries, and two Python examples. `SHA256SUMS` covers the original files and this README. No SSH keys, passwords, desktop settings, OpenClaw state or unrelated camera SDK is included.

| Program | Configuration in source | Purpose |
| --- | --- | --- |
| `bno055_fixed.cpp` | `/dev/i2c-1`, address `0x28` | Chip-ID check, reset/init, Euler angles, gyro, calibration;50ms loop |
| `bno055_read.cpp` | `/dev/i2c-4`, address `0x29` first | Euler angles and gyro;100ms loop |
| `simple_test.cpp` | `/dev/i2c-4`, address `0x29` | One chip-ID register read |
| `bno055_direct_i2c.py` | SMBus1, `0x28` then `0x29` | Bus scan and sensor initialization example |
| `bno055_i2c_read.py` | `board.SCL` / `board.SDA`, `0x28` | Adafruit init, temperature and calibration |

These are existing experiments, not a packaged production driver. No BNO055 process or startup service was found running during this transfer. Live sensor readings were not tested; the programs can change sensor mode/reset it, so copying and compile checks do not establish hardware readiness.

## Moving to another ELF board

Copy the archive to the other board, extract it, enter the extracted folder, and verify:

```text
sha256sum --check SHA256SUMS
```

The preserved binaries are ARM64 and cannot execute on .191's x86_64 CPU. Rebuild on the destination board rather than assuming binary compatibility. The C++ code uses Linux I2C headers and the standard C++ library; the source board has g++11.4.0. Example build commands from the extracted folder:

```text
mkdir -p build
g++ -std=c++17 -O2 original/bno055_fixed.cpp -o build/bno055_fixed
g++ -std=c++17 -O2 original/bno055_read.cpp -o build/bno055_read
g++ -std=c++17 -O2 original/simple_test.cpp -o build/simple_test
```

Before running, confirm the other board's enabled I2C controller, matching header pins, sensor address and access permissions, then adjust the hardcoded bus/address in a working copy. Bus numbering is not consistent across these original examples. Source-board user `elf` belongs to `i2c`; `/dev/i2c-*` is owned by root:i2c with0660 access. No board-header pin numbers or electrical supply are documented in this code; use the actual target/module pinout instead of inferring them from `/dev/i2c-N`.

Python3.10.12 is present on the source board. The direct example imports `smbus`; the Adafruit example imports `board`, `busio`, `adafruit_bno055` (Blinka and CircuitPython BNO055). Their installation was not confirmed. The C++ route avoids these Python dependencies. No dependencies or startup services are installed on .191 by this transfer.

## Known issues retained in the original

- `bno055_direct_i2c.py` misspells the0x29 fallback class as `BNO55Direct`; the defined class is `BNO055Direct`.
- The Adafruit reader accepts `i2c_bus` but does not use it; it always selects the board.SCL/SDA mapping.
- `bno055_read.cpp` calls exit on bus/address setup failure, so its catch block does not implement a reliable address fallback. Its raw reads also do not validate short transfers.
- Some comments/status interpretations in the experimental fixed reader should be checked against the sensor datasheet before production use. All8 originals remain unchanged for faithful recovery.

Compile-check outputs on .191 live separately under `verification/x86_64/`; they are not replacements for the original ARM64 binaries and are not needed when copying the archive to another ELF board.
