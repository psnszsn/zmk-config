import sys
import os
import time
import pyudev
import subprocess
from pathlib import Path


def uf2_file():
    directory = Path("./firmware")
    files = directory.glob("*.uf2")
    newest_file = max(files, key=lambda f: f.stat().st_mtime)
    return newest_file


UF2_FILE_PATH = os.getenv("UF2", uf2_file())


def wait_for_pico():
    context = pyudev.Context()
    monitor = pyudev.Monitor.from_netlink(context)
    monitor.filter_by(subsystem="block")

    print("Waiting for Raspberry Pi Pico to be connected...")
    for device in iter(monitor.poll, None):
        print(device.get("ID_VENDOR_ID"))
        if device.action == "add" and device.get("ID_VENDOR_ID") in ["239a", "2886"]:
            if node := device.device_node:
                sys.stdout.write(node + "\n")
                return node
        time.sleep(1)


def write_uf2_file(dev_node):
    """Write the UF2 file to the Raspberry Pi Pico using dd."""
    print(f"Writing {UF2_FILE_PATH} to {dev_node} using dd...")
    subprocess.run(
        ["dd", f"if={UF2_FILE_PATH}", f"of={dev_node}", "bs=1M", "conv=fsync"],
        check=True,
    )
    print("UF2 file successfully written!")


def main():
    while True:
        pico_dev_node = wait_for_pico()
        if pico_dev_node:
            write_uf2_file(pico_dev_node)
            break
        else:
            print("Pico not found. Retrying...")


if __name__ == "__main__":
    main()
