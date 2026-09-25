"""Local MCP stdio server for this Godot project. Python 3.12+, no packages.

JSON-RPC lines only on stdout. No shell execution or arbitrary filesystem access.
"""
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
EXTENSIONS = {".gd", ".tscn", ".tres", ".godot", ".md", ".json"}
SKIP = {".git", ".godot", ".codex", ".agents", "__pycache__", "artifacts"}


def engine():
    override = os.environ.get("GODOT_BIN")
    if override:
        path = Path(override).resolve()
        if not path.is_file():
            raise ValueError("GODOT_BIN does not point to a file")
        return path
    candidates = sorted((ROOT / "tools" / "godot").glob("Godot*_win64.exe"))
    if not candidates:
        raise ValueError("Set GODOT_BIN to your Godot 4 executable")
    return candidates[0]


def source_path(relative):
    if not isinstance(relative, str):
        raise ValueError("path must be a relative string")
    path = (ROOT / relative.removeprefix("res://")).resolve()
    if not path.is_relative_to(ROOT):
        raise ValueError("Path must stay inside project")
    parts = path.relative_to(ROOT).parts
    if any(part.startswith(".") or part in SKIP for part in parts):
        raise ValueError("Internal files are not exposed")
    if path.suffix not in EXTENSIONS or not path.is_file():
        raise ValueError("Not a supported project source file")
    if path.stat().st_size > 256_000:
        raise ValueError("File exceeds 256 KB limit")
    return path


def files():
    result = []
    for directory, dirs, names in os.walk(ROOT, followlinks=False):
        dirs[:] = [d for d in dirs if d not in SKIP and not d.startswith(".")
                   and not (Path(directory) / d).is_symlink()
                   and not (Path(directory) / d).is_junction()]
        for name in names:
            path = Path(directory) / name
            if path.suffix in EXTENSIONS and not path.is_symlink():
                result.append(path.relative_to(ROOT).as_posix())
    return sorted(result)


def run_godot(arguments, timeout=45):
    (ROOT / "artifacts").mkdir(exist_ok=True)
    command = [str(engine()), "--headless", "--path", str(ROOT),
               "--log-file", str(ROOT / "artifacts" / "mcp-godot.log"), *arguments]
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                            encoding="utf-8", errors="replace", timeout=timeout,
                            creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
    output = result.stdout + result.stderr
    ok = result.returncode == 0 and "SCRIPT ERROR" not in output and "ERROR:" not in output
    return {"ok": ok, "exit_code": result.returncode, "output": output[-18000:]}


TOOLS = [
    {"name": "project_info", "description": "Read Godot version, project config and source inventory.",
     "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False}},
    {"name": "read_source", "description": "Read a Godot project source file by relative path.",
     "inputSchema": {"type": "object", "properties": {"path": {"type": "string"}}, "required": ["path"], "additionalProperties": False}},
    {"name": "validate_project", "description": "Load the main scene headlessly for 8 frames and report errors. Executes project scripts.",
     "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False}},
    {"name": "test_combat", "description": "Run combat and round lifecycle regression tests in Godot.",
     "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False}},
]


def call_tool(name, args):
    if not isinstance(args, dict):
        raise ValueError("arguments must be an object")
    expected = {"path"} if name == "read_source" else set()
    if set(args) != expected:
        raise ValueError("Unexpected or missing arguments")
    if name == "project_info":
        return {"root": str(ROOT), "engine": run_godot(["--version"]),
                "config": (ROOT / "project.godot").read_text(encoding="utf-8"), "files": files()}
    if name == "read_source":
        return {"path": args["path"], "source": source_path(args["path"]).read_text(encoding="utf-8")}
    if name == "validate_project":
        return run_godot(["--quit-after", "8"])
    if name == "test_combat":
        return run_godot(["--script", "res://tests/combat_test.gd"])
    raise ValueError("Unknown tool")


def dispatch(request):
    if not isinstance(request, dict) or request.get("jsonrpc") != "2.0" or not isinstance(request.get("method"), str):
        return {"jsonrpc": "2.0", "id": None, "error": {"code": -32600, "message": "Invalid Request"}}
    if "id" not in request:
        return None
    method = request["method"]
    params = request.get("params", {})
    reply = {"jsonrpc": "2.0", "id": request["id"]}
    if method == "initialize":
        version = params.get("protocolVersion", "2025-03-26")
        reply["result"] = {"protocolVersion": version if version in {"2024-11-05", "2025-03-26", "2025-06-18"} else "2025-03-26",
                           "capabilities": {"tools": {"listChanged": False}},
                           "serverInfo": {"name": "lumenfall-godot", "version": "1.0.0"},
                           "instructions": "Tools are scoped to the Lumenfall project. Validate and test execute project GDScript headlessly. No live editor control is provided."}
    elif method == "ping":
        reply["result"] = {}
    elif method == "tools/list":
        reply["result"] = {"tools": TOOLS}
    elif method == "tools/call":
        try:
            value = call_tool(params.get("name"), params.get("arguments", {}))
            reply["result"] = {"content": [{"type": "text", "text": json.dumps(value, ensure_ascii=False)}],
                               "isError": value.get("ok") is False}
        except (ValueError, OSError, subprocess.SubprocessError) as exc:
            reply["result"] = {"content": [{"type": "text", "text": str(exc)}], "isError": True}
    else:
        reply["error"] = {"code": -32601, "message": "Method not found"}
    return reply


def main():
    sys.stdin.reconfigure(encoding="utf-8")
    sys.stdout.reconfigure(encoding="utf-8")
    for line in sys.stdin:
        try:
            reply = dispatch(json.loads(line))
        except json.JSONDecodeError:
            reply = {"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": "Parse error"}}
        except (TypeError, AttributeError) as exc:
            reply = {"jsonrpc": "2.0", "id": None, "error": {"code": -32602, "message": str(exc)}}
        if reply is not None:
            print(json.dumps(reply, ensure_ascii=False), flush=True)


if __name__ == "__main__":
    main()
