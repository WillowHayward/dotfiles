#!/usr/bin/env python3
"""Fail if any just recipe (root or setup module) has no doc comment for `just --list`."""
import json
import subprocess
import sys


def undocumented(recipes, prefix=""):
    return [f"{prefix}{name}" for name, recipe in recipes.items() if not recipe.get("doc")]


dump = json.loads(subprocess.run(["just", "--dump", "--dump-format", "json"], capture_output=True, text=True, check=True).stdout)
missing = undocumented(dump["recipes"])
for module, body in dump.get("modules", {}).items():
    missing += undocumented(body["recipes"], f"{module} ")
if missing:
    sys.exit("just recipes without a doc comment: " + ", ".join(missing))
print("every just recipe is documented")
