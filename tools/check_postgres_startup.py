"""Exercise the built API against a disposable PostgreSQL database."""
import json
import os
import secrets
import subprocess
import sys
import time
from contextlib import contextmanager
from pathlib import Path
from urllib.error import URLError
from urllib.request import Request, urlopen

binary = Path(sys.argv[1]).resolve()
address = "127.0.0.1:29471"
env = dict(os.environ, HTTP_ADDR=address, APP_ENV="prod",
           CONTENT_PACKAGES_ROOT=str(Path(__file__).resolve().parents[1] / "content/packages"))
if not env.get("DATABASE_URL"):
    sys.exit("Set DATABASE_URL to a disposable PostgreSQL database")


def request(path, token=None, body=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    data = json.dumps(body).encode() if body is not None else None
    with urlopen(Request(f"http://{address}/api/v1/{path}", data, headers), timeout=3) as response:
        return json.load(response)


@contextmanager
def running_api():
    process = subprocess.Popen([binary], env=env)
    try:
        for _ in range(100):
            if process.poll() is not None:
                raise RuntimeError("API exited during startup")
            try:
                health = request("health")
                assert health["db"] and health["store"] == "postgres"
                break
            except URLError:
                time.sleep(0.1)
        else:
            raise RuntimeError("API startup timed out")
        yield
    finally:
        process.terminate()
        process.wait(timeout=5)


with running_api():
    guest = request("auth/guest", body={})
    token = guest["access_token"]
    profile = request("player/profile", token)
    assert profile["account_id"] == guest["account_id"] and profile["level"] == 1
    assert request("player/heartbeat", token, {})["ok"]
    credentials = {"email": secrets.token_hex(8) + "@example.invalid", "password": secrets.token_hex(16)}
    account = request("auth/register", body=credentials)
    login = request("auth/login", body=credentials)
    assert request("player/profile", login["access_token"])["account_id"] == account["account_id"]

with running_api():
    assert request("auth/me", token)["account_id"] == guest["account_id"]
    assert request("player/profile", token) == profile
    assert request("player/heartbeat", token, {})["ok"]
print("PostgreSQL startup, authentication, profile, heartbeat and session restore passed")
