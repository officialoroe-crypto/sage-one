from __future__ import annotations

import hashlib
import os
from pathlib import Path
import shutil
import tempfile
from typing import Any

from dev_agent.agent import DevelopmentAgent
from dev_agent.policy import AgentPolicy


IGNORED_DIRS = {
    ".git", ".venv", "venv", "node_modules", "__pycache__", ".dart_tool",
    "build", "dist", "target", ".pytest_cache", ".mypy_cache", ".ruff_cache",
}
FORBIDDEN_NAMES = {
    ".env", ".env.local", ".env.production", "credentials.json", "id_rsa",
    "id_ed25519",
}
MAX_FILE_BYTES = 1_000_000
MAX_PATCH_BYTES = 2_000_000


class StaleDeveloperProposal(RuntimeError):
    """Raised when a workspace changed after its proposal was previewed."""


def _ignore(directory: str, names: list[str]) -> set[str]:
    ignored = set()
    for name in names:
        lowered = name.lower()
        if name in IGNORED_DIRS or lowered.startswith(".env") or lowered in FORBIDDEN_NAMES or lowered.endswith((".pem", ".key", ".p12", ".pfx")):
            ignored.add(name)
        elif lowered.endswith((".pem", ".key", ".p12", ".pfx")):
            ignored.add(name)
    return ignored


def _digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _snapshot(root: Path) -> dict[str, bytes]:
    snapshot: dict[str, bytes] = {}
    for path in root.rglob("*"):
        if not path.is_file() or path.is_symlink():
            continue
        relative = path.relative_to(root).as_posix()
        if any(part in IGNORED_DIRS for part in Path(relative).parts):
            continue
        if Path(relative).name.lower().startswith(".env") or Path(relative).name.lower() in FORBIDDEN_NAMES:
            continue
        if Path(relative).name.lower().endswith((".pem", ".key", ".p12", ".pfx")):
            continue
        try:
            data = path.read_bytes()
        except OSError:
            continue
        if len(data) <= MAX_FILE_BYTES:
            snapshot[relative] = data
    return snapshot


def prepare_developer_preview(workspace: str, task: str) -> dict[str, Any]:
    """Run the coding agent in an isolated copy and return an exact, bounded patch."""
    original = Path(workspace).resolve()
    if not original.is_dir():
        return {"success": False, "response": "Workspace does not exist.", "changes": []}

    before = _snapshot(original)
    total_size = 0
    with tempfile.TemporaryDirectory(prefix="sage-developer-preview-") as temp:
        sandbox = Path(temp) / "workspace"
        shutil.copytree(original, sandbox, ignore=_ignore, symlinks=True)
        result = DevelopmentAgent(str(sandbox), apply_changes=True).apply(task)
        if not result.get("success"):
            return {
                "success": False,
                "response": result.get("response") or "The isolated implementation attempt failed.",
                "provider": result.get("provider"),
                "model": result.get("model"),
                "changes": [],
            }
        after = _snapshot(sandbox)
        deleted = sorted(set(before) - set(after))
        if deleted:
            return {
                "success": False,
                "response": "Preview rejected: deleting files is not supported by the safe apply workflow.",
                "changes": [],
                "rejected_paths": deleted[:50],
            }

        changes = []
        policy = AgentPolicy(original)
        for relative in sorted(after):
            old, new = before.get(relative), after[relative]
            if old == new:
                continue
            if not policy.can_write(relative):
                return {
                    "success": False,
                    "response": f"Preview rejected: proposed change is outside approved writable roots: {relative}",
                    "changes": [],
                }
            name = Path(relative).name.lower()
            if name in FORBIDDEN_NAMES or name.endswith((".pem", ".key", ".p12", ".pfx")):
                return {"success": False, "response": "Preview rejected: protected file change.", "changes": []}
            total_size += len(new)
            if total_size > MAX_PATCH_BYTES:
                return {"success": False, "response": "Preview rejected: patch exceeds the 2 MB safety limit.", "changes": []}
            try:
                text = new.decode("utf-8")
            except UnicodeDecodeError:
                return {"success": False, "response": f"Preview rejected: non-text file changes are not supported: {relative}", "changes": []}
            changes.append({
                "path": relative,
                "before_sha256": _digest(old) if old is not None else None,
                "after_sha256": _digest(new),
                "before_content": old.decode("utf-8") if old is not None else None,
                "content": text,
            })

        if not changes:
            return {
                "success": False,
                "response": "No approved source-file changes were produced in the isolated preview. Nothing was changed.",
                "provider": result.get("provider"),
                "model": result.get("model"),
                "changes": [],
            }
        return {
            "success": True,
            "response": result.get("response", "Patch prepared in an isolated workspace."),
            "provider": result.get("provider"),
            "model": result.get("model"),
            "changes": changes,
            "change_count": len(changes),
            "patch_bytes": total_size,
            "checks": "Exact file contents and before/after hashes were captured in an isolated workspace. Review the agent response and require CI/relevant tests before release.",
        }


def apply_developer_preview(workspace: str, preview: dict[str, Any]) -> dict[str, Any]:
    """Apply the exact stored patch only if every source file still matches its preview."""
    root = Path(workspace).resolve()
    changes = preview.get("changes")
    if not isinstance(changes, list) or not changes:
        raise ValueError("This proposal contains no applicable file changes.")

    policy = AgentPolicy(root)
    prepared: list[tuple[Path, bytes | None, bytes, int | None]] = []
    total_size = 0
    for item in changes:
        relative = str(item.get("path", ""))
        if not policy.can_write(relative):
            raise PermissionError(f"Proposed path is not writable: {relative}")
        relative_path = Path(relative)
        if relative_path.is_absolute() or any(part in {".", ".."} for part in relative_path.parts):
            raise PermissionError(f"Invalid relative path in proposal: {relative}")
        candidate = root
        for part in relative_path.parts:
            candidate = candidate / part
            if candidate.is_symlink():
                raise PermissionError(f"Symlink writes are not permitted: {relative}")
        target = policy.resolve(relative)
        current = target.read_bytes() if target.is_file() else None
        expected = item.get("before_sha256")
        if (_digest(current) if current is not None else None) != expected:
            raise StaleDeveloperProposal(f"Workspace changed since preview: {relative}. Create a new preview.")
        content = item.get("content")
        if not isinstance(content, str):
            raise ValueError(f"Invalid proposed text content: {relative}")
        encoded = content.encode("utf-8")
        if len(encoded) > MAX_FILE_BYTES or _digest(encoded) != item.get("after_sha256"):
            raise ValueError(f"Proposed content integrity check failed: {relative}")
        total_size += len(encoded)
        if total_size > MAX_PATCH_BYTES:
            raise ValueError("Proposal exceeds the 2 MB safety limit.")
        mode = target.stat().st_mode if target.exists() else None
        prepared.append((target, current, encoded, mode))

    written: list[tuple[Path, bytes | None, int | None]] = []
    try:
        for target, old, encoded, mode in prepared:
            target.parent.mkdir(parents=True, exist_ok=True)
            fd, temp_name = tempfile.mkstemp(prefix=".sage-proposal-", dir=str(target.parent))
            try:
                with os.fdopen(fd, "wb") as handle:
                    handle.write(encoded)
                    handle.flush()
                    os.fsync(handle.fileno())
                os.chmod(temp_name, mode if mode is not None else 0o644)
                os.replace(temp_name, target)
            finally:
                if os.path.exists(temp_name):
                    os.unlink(temp_name)
            written.append((target, old, mode))
    except Exception:
        for target, old, mode in reversed(written):
            if old is None:
                target.unlink(missing_ok=True)
            else:
                target.write_bytes(old)
                if mode is not None:
                    os.chmod(target, mode)
        raise

    return {
        "success": True,
        "response": "Applied the exact approved preview; the coding agent was not rerun.",
        "changed_paths": [str(target.relative_to(root)).replace("\\", "/") for target, _, _, _ in prepared],
        "change_count": len(prepared),
        "verified_hashes": True,
    }
