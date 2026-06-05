#!/usr/bin/env python3

import os
import sys
import argparse
import shutil
import stat
import tempfile
import filecmp
import subprocess
from datetime import datetime

import requests

SINGBOX_CONFIG_FILENAME = "config.json"
SINGBOX_SERVICE_NAME = "sing-box"
REMOTE_SCRIPT_PATH = "docker/microbox/bin/microhelper.py"


def getenv_required(name: str) -> str:
    value = os.getenv(name)
    if not value:
        print(f"ERROR: environment variable {name} is not set", file=sys.stderr)
        sys.exit(1)
    return value


def download_file(url: str, path: str):
    response = requests.get(url, timeout=30)
    response.raise_for_status()

    with open(path, "wb") as f:
        f.write(response.content)


def restart_singbox():
    print("Restarting sing-box...")

    result = subprocess.run(
        ["supervisorctl", "restart", SINGBOX_SERVICE_NAME],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print("ERROR: failed to restart sing-box", file=sys.stderr)
        print(result.stderr, file=sys.stderr)
        sys.exit(1)

    print(result.stdout.strip())


def self_update():
    repository_url = getenv_required("REPOSITORY_URL")

    script_url = "{}/{}".format(repository_url.rstrip("/"), REMOTE_SCRIPT_PATH)
    current_script = os.path.realpath(__file__)
    current_dir = os.path.dirname(current_script)

    with tempfile.NamedTemporaryFile(prefix="microhelper_", dir=current_dir, delete=False) as tmp:
        tmp_path = tmp.name

    try:
        print(f"Downloading latest script from {script_url}")
        download_file(script_url, tmp_path)

        current_mode = os.stat(current_script).st_mode
        os.chmod(
            tmp_path,
            current_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH,
        )

        os.replace(tmp_path, current_script)
        print("Self-update completed successfully.")

    finally:
        if os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except OSError:
                pass


def update(restart=False):
    remote_url = getenv_required("SINGBOX_REMOTE_URL")
    config_dir = getenv_required("SINGBOX_CONFIG_DIR")
    backup_dir = getenv_required("BACKUP_DIR")

    os.makedirs(config_dir, exist_ok=True)
    os.makedirs(backup_dir, exist_ok=True)

    current_config = os.path.join(config_dir, SINGBOX_CONFIG_FILENAME)
    is_current_exist = os.path.exists(current_config)

    with tempfile.TemporaryDirectory(prefix="microhelper-") as tmpdir:
        downloaded_config = os.path.join(tmpdir, SINGBOX_CONFIG_FILENAME)

        print(f"Downloading config from {remote_url}")
        download_file(remote_url, downloaded_config)

        if is_current_exist and filecmp.cmp(current_config, downloaded_config, shallow=False):
            print("Configuration is already up to date.")
            return

        print("Checking downloaded configuration...")
        result = subprocess.run(
            ["sing-box", "-C", tmpdir, "check"],
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            print("ERROR: sing-box configuration validation failed", file=sys.stderr)
            if result.stdout:
                print(result.stdout, file=sys.stderr)
            if result.stderr:
                print(result.stderr, file=sys.stderr)
            sys.exit(1)

        if is_current_exist:
            timestamp = datetime.now().strftime("%Y%m%d")
            backup_file = os.path.join(
                backup_dir,
                f"{timestamp}_{SINGBOX_CONFIG_FILENAME}",
            )

            shutil.copy2(current_config, backup_file)
            print(f"Backup created: {backup_file}")

        shutil.move(downloaded_config, current_config)
        print("Configuration updated successfully.")

    if restart:
        restart_singbox()


def usage():
    print(
        f"Usage: {os.path.basename(sys.argv[0])} "
        "[update|self-update]"
    )


def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(
        dest="command",
        required=True,
    )

    subparsers.add_parser("self-update")

    update_parser = subparsers.add_parser("update")
    update_parser.add_argument(
        "--restart",
        action="store_true",
        help="restart sing-box service after update",
    )

    args = parser.parse_args()
    if args.command == "self-update":
        self_update()
    elif args.command == "update":
        update(restart=args.restart)
    else:
        usage()
        sys.exit(1)

if __name__ == "__main__":
    main()
