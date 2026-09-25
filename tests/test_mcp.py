"""Exercise real stdio transport, source boundaries and actual Godot tools."""
import json
from pathlib import Path
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]


class MCPTests(unittest.TestCase):
    def test_stdio_session(self):
        messages = [
            {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-03-26", "capabilities": {}, "clientInfo": {"name": "test", "version": "1"}}},
            {"jsonrpc": "2.0", "method": "notifications/initialized"},
            {"jsonrpc": "2.0", "id": 2, "method": "tools/list"},
            {"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "read_source", "arguments": {"path": "scripts/fighter.gd"}}},
            {"jsonrpc": "2.0", "id": 4, "method": "tools/call", "params": {"name": "read_source", "arguments": {"path": "../outside.md"}}},
            {"jsonrpc": "2.0", "id": 5, "method": "tools/call", "params": {"name": "read_source", "arguments": {"path": ".codex/config.toml"}}},
            {"jsonrpc": "2.0", "id": 6, "method": "tools/call", "params": {"name": "project_info", "arguments": {}}},
            {"jsonrpc": "2.0", "id": 7, "method": "tools/call", "params": {"name": "validate_project", "arguments": {}}},
            {"jsonrpc": "2.0", "id": 8, "method": "tools/call", "params": {"name": "test_combat", "arguments": {}}},
            {"jsonrpc": "2.0", "id": 9, "method": "invalid"},
        ]
        result = subprocess.run([sys.executable, str(ROOT / "tools/godot_mcp.py")],
                                input="\n".join(json.dumps(m) for m in messages) + "\n",
                                capture_output=True, text=True, encoding="utf-8", timeout=100)
        self.assertEqual(result.returncode, 0, result.stderr)
        replies = {r["id"]: r for r in map(json.loads, result.stdout.splitlines())}
        self.assertEqual(len(replies), 9, result.stdout)
        self.assertEqual(replies[1]["result"]["protocolVersion"], "2025-03-26")
        self.assertEqual(len(replies[2]["result"]["tools"]), 4)
        self.assertFalse(replies[3]["result"]["isError"])
        self.assertTrue(replies[4]["result"]["isError"])
        self.assertTrue(replies[5]["result"]["isError"])
        self.assertFalse(replies[6]["result"]["isError"], replies[6])
        for number in [7, 8]:
            self.assertFalse(replies[number]["result"]["isError"], replies[number])
        tests = json.loads(replies[8]["result"]["content"][0]["text"])
        self.assertIn("ARENA TESTS: PASS", tests["output"])
        self.assertEqual(replies[9]["error"]["code"], -32601)


if __name__ == "__main__":
    unittest.main(verbosity=2)
