#!/usr/bin/env python3
"""Check the shipped native lockfile against OSV, including maintenance notices."""

import argparse
import json
from pathlib import Path
import sys
import tomllib
from urllib.request import Request, urlopen


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "lockfile", nargs="?",
        default="vendor/security/wireguardex/native/wireguard_nif/Cargo.lock",
    )
    args = parser.parse_args()
    packages = tomllib.loads(Path(args.lockfile).read_text())["package"]
    queries = [
        {"package": {"name": item["name"], "ecosystem": "crates.io"}, "version": item["version"]}
        for item in packages if item.get("source", "").startswith("registry+")
    ]
    request = Request(
        "https://api.osv.dev/v1/querybatch",
        data=json.dumps({"queries": queries}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "Firezone-Plus-native-audit"},
    )
    with urlopen(request, timeout=60) as response:
        results = json.load(response)["results"]
    if len(results) != len(queries):
        raise RuntimeError("OSV returned an incomplete batch")
    findings = [
        {"package": query["package"]["name"], "version": query["version"],
         "advisories": sorted({item["id"] for item in result["vulns"]})}
        for query, result in zip(queries, results) if result.get("vulns")
    ]
    print(json.dumps({"registry_packages_checked": len(queries), "findings": findings}, indent=2))
    return bool(findings)


if __name__ == "__main__":
    sys.exit(main())
