#!/usr/bin/env python3

import os
import sys
import json
import shutil
import logging
import subprocess
import tempfile
from pprint import pprint
from pathlib import Path

import pexpect
import requests
import jinja2

logging.basicConfig(
    level=logging.INFO,
    format="[%(name)s][%(levelname)s] %(message)s",
)
LOGGER = logging.getLogger("resource-manager")


def check_executable_exist(executable: str):
    return bool(shutil.which(executable))


def rage_decrypt(src: str, dst: str, passphrase: str) -> int:
    assert len(passphrase) > 0
    LOGGER.info(f"rage decrypting {src} ...")
    env = os.environ.copy()
    env["PINENTRY_PROGRAM"] = ""

    child = pexpect.spawn(
        "rage",
        ["-d", "-o", dst, src],
        env=env,
        encoding="utf-8",
    )

    while True:
        idx = child.expect([r"Type passphrase.*",pexpect.EOF])
        if idx == 0:
            child.sendline(passphrase)
        else:
            break

    child.close()

    if child.exitstatus != 0:
        raise ValueError(f"Error rage decrypt: {src}")


class ResourceManager:
    META_FILENAME = ".meta.json"
    DEFAULT_ENCRYPTION_HANDLER = "rage"
    ENV_PREFIX = "RESOURCE"

    logger = LOGGER

    def __init__(self, directory: str):
        self.directory = Path(directory).resolve()
        self.meta_file = self.directory / self.META_FILENAME

        if not self.meta_file.exists():
            raise FileNotFoundError(f"meta file not found: {self.meta_file}")

        with open(self.meta_file, "r", encoding="utf-8") as f:
            self.meta = json.load(f)

        self.base_url = self.meta.get("base_url")
        self.base_path = self.meta.get("base_path")

        self.resolve_env()
        self.resolve_meta()
        self.logger.info(f"initialized at directory: {self.directory}")

    @classmethod
    def download_file(cls, url: str, output_file: Path):
        cls.logger.info(f"requesting {url} ...")
        response = requests.get(url, timeout=30)
        response.raise_for_status()

        with open(output_file, "wb") as f:
            f.write(response.content)

    def resolve_update_config(self, update_config: dict, filename=None):
        if update_config.get("url"):
            return update_config

        base_url = update_config.get("base_url") or self.base_url
        base_path = update_config.get("base_path") or self.base_path
        filename = update_config.get("filename") or filename

        if not base_url:
            raise ValueError(f"missing base_url in {update_config}")
        if not base_path:
            raise ValueError(f"missing base_path in {update_config}")
        if not filename:
            raise ValueError(f"missing filename in {update_config}")

        url = f"{base_url.rstrip('/')}/{base_path.rstrip('/')}/{filename}"

        return {
            "base_url": base_url,
            "base_path": base_path,
            "filename": filename,
            "url": url,
        }

    def resolve_encryption_config(self, encryption_config: dict, filename=None):
        handler = encryption_config.get("handler", self.DEFAULT_ENCRYPTION_HANDLER)
        if not check_executable_exist(handler):
            raise FileNotFoundError(f"Error finding executable {handler}")
        if handler == "rage":
            encryption_config["passphrase"] = encryption_config.get('passphrase') or os.getenv("RAGE_PASSPHRASE")
            if not encryption_config["passphrase"]:
                raise ValueError(f"missing passphrase in {encryption_config}")

    def resolve_template_config(self, template_config: dict, filename=None):
        template_config["use_env"] = template_config.get("use_env", False)
        template_config["params"] = template_config.get("params", {})

    def resolve_resource(self, resource: dict):
        ix = resource.get("_index")
        resource["targets"] = resource.get("targets", [])
        
        # filename
        filename = resource.get("filename")
        if not filename:
            raise ValueError(f"missing filename in resource[{ix}]")

        resource["update_enabled"] = resource.get("update_enabled", False)
        resource["update_config"] = resource.get("update_config", {})
        self.resolve_update_config(resource["update_config"], filename=filename)

        resource["encryption_enabled"] = resource.get("encryption_enabled", False)
        resource["encryption_config"] = resource.get("encryption_config", {})
        if resource["encryption_enabled"]:
            self.resolve_encryption_config(resource["encryption_config"], filename=filename)

        resource["template_enabled"] = resource.get("template_enabled", False)
        resource["template_config"] = resource.get("template_config", {})
        if resource["template_enabled"]:
            self.resolve_template_config(resource["template_config"], filename=filename)

    def resolve_meta(self):
        try:
            self.meta["update_config"] = self.resolve_update_config(
                self.meta["update_config"], filename=self.META_FILENAME)
        except ValueError as e:
            raise ValueError(f"Error resolving meta update config: {e}")

        self.meta["resources"] = self.meta.get("resources", [])
        for i, res in enumerate(self.meta["resources"]):
            res["_index"] = i
            try:
                self.resolve_resource(res)
            except ValueError as e:
                raise ValueError(f"Error resolving resource update config[{res['_index']}]: {e}")

    def resolve_env(self):
        base_url = os.getenv(f"{self.ENV_PREFIX}_BASE_URL")
        if base_url:
            self.base_url = base_url
        base_path = os.getenv(f"{self.ENV_PREFIX}_BASE_PATH")
        if base_path:
            self.base_path = base_path

    def switch_content(self, resource, filepath, is_temp=True):
        if resource["_content_path_is_temp"]:
            resource["_content_path"].unlink(missing_ok=True)
        resource["_content_path"] = filepath
        resource["_content_path_is_temp"] = is_temp

    def handle_decrypt(self, encryption_config, src, dst=None):
        is_tempfile = False
        handler = encryption_config["handler"]
        if src.name.endswith('.age'):
            dst = src.parent / src.name.removesuffix('.age')
        if dst is None:
            with tempfile.NamedTemporaryFile(delete=False) as f:
                dst = Path(f.name)
                is_tempfile = True

        if handler == "rage":
            rage_decrypt(str(src), str(dst), encryption_config["passphrase"])
        else:
            raise ValueError(f"Error decrypting, unknown handler: {handler}")
        return dst, is_tempfile

    def handle_render(self, template_config, src, dst=None):
        env = jinja2.Environment(trim_blocks=True, lstrip_blocks=True, undefined=jinja2.StrictUndefined)
        tmpl = env.from_string(src.read_text())
        params = template_config["params"]
        if template_config["use_env"]:
            params.update(os.environ)
        params_provider = template_config.get("params_provider")
        if params_provider:
            try:
                proc = subprocess.run([params_provider], capture_output=True, text=True, check=True)
            except subprocess.CalledProcessError as e:
                self.logger.info(f"subprocess failed with exit code {e.returncode}, {e.stderr}")
                raise
            else:
                res = json.loads(proc.stdout)
                params.update(res)

        content = tmpl.render(**params)
        if dst is None:
            with tempfile.NamedTemporaryFile('w', encoding="utf-8" ,delete=False) as f:
                dst = Path(f.name)
                f.write(content)
        return dst, True

    def print_config(self):
        print(json.dumps(self.meta, indent=2, ensure_ascii=False))

    def delete(self):
        for res in self.meta["resources"]:
            res_path = self.directory / res["filename"]
            res_path.unlink(missing_ok=True)

    def download(self):
        for res in self.meta["resources"]:
            res_path = self.directory / res["filename"]
            if res_path.exists():
                self.logger.info(f"{res['filename']} found, skipped")
            else:
                self.download_file(res["update_config"]["url"], res_path)
                self.logger.info(f"{res['filename']} downloaded")

    def update(self):
        for res in self.meta["resources"]:
            if res["update_enabled"]:
                self.download_file(res["update_config"]["url"], self.directory / res["filename"])
                self.logger.info(f"{res['filename']} updated")

    def load_status(self):
        for res in self.meta["resources"]:
            res_path = self.directory / res["filename"]
            res["_exist"] = res_path.exists()
            res["_content_path"] = res_path if res["_exist"] else None
            res["_content_path_is_temp"] = False if res["_exist"] else None
            targets = []
            for target in res["targets"]:
                if not target:
                    continue
                target = Path(target)
                if target and target.exists() and target.is_dir():
                    target = target / res["filename"]
                targets.append(target)
            res["_target_path_list"] = targets

    def print_status(self):
        self.load_status()
        for res in self.meta["resources"]:
            pprint(res)

    def decrypt(self):
        for res in self.meta["resources"]:
            if res["encryption_enabled"] and res["_content_path"]:
                fp, is_temp = self.handle_decrypt(res["encryption_config"], res["_content_path"])
                self.switch_content(res, fp, is_temp)

    def render(self):
        for res in self.meta["resources"]:
            if res["template_enabled"] and res["_content_path"]:
                fp, is_temp = self.handle_render(res["template_config"], res["_content_path"])
                self.switch_content(res, fp, is_temp)

    def output(self):
        for res in self.meta["resources"]:
            for target in res["_target_path_list"]:
                if target and res["_content_path"]:
                    if target.exists():
                        self.logger.info(f"overwriting file at {target} ...")
                    else:
                        self.logger.info(f"creating file at {target} ...")
                    shutil.copy2(res["_content_path"], target)

    def cleanup(self):
        for res in self.meta["resources"]:
            if res.get("_content_path_is_temp"):
                self.logger.info(f"cleanup temporary file at {res['_content_path']} ...")
                res["_content_path"].unlink(missing_ok=True)
                res["_content_path"] = None


def usage():
    print(
        f"Usage: {Path(sys.argv[0]).name} <directory> "
        "[print|delete|download|update|status|decrypt|render|all]"
    )


def main():
    if len(sys.argv) != 3:
        usage()
        sys.exit(1)

    directory = sys.argv[1]
    action = sys.argv[2]

    manager = ResourceManager(directory)

    actions = {
        "print": [manager.print_config],
        "delete": [manager.delete],
        "download": [manager.download],
        "update": [manager.update],
        "status": [manager.print_status],
        "decrypt": [manager.load_status, manager.decrypt, manager.output],
        "render": [manager.load_status, manager.decrypt, manager.render, manager.output],
        "all": [manager.update, manager.load_status, manager.decrypt, manager.render, manager.output],
    }

    funcs = actions.get(action)

    if not funcs:
        usage()
        sys.exit(1)

    try:
        for func in funcs:
            func()
    finally:
        manager.cleanup()


if __name__ == "__main__":
    main()
