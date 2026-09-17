from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import shlex


@dataclass(frozen=True)
class AgentPolicy:
    """Safety policy for the SAGE development agent.

    The agent can edit source/tests and run non-destructive checks. Secrets,
    git history mutation, deployment, package publishing, and arbitrary shell
    commands are outside the default authority boundary.
    """

    workspace: Path
    auto_write: bool = False
    allow_tests: bool = True

    writable_roots: tuple[str, ...] = (
        "app",
        "agents",
        "brain",
        "config",
        "database",
        "dev_agent",
        "execution",
        "memory",
        "missions",
        "permissions",
        "projects",
        "research",
        "tasks",
        "tools",
        "web",
        "tests",
        "docs",
        ".github",
    )

    forbidden_names: tuple[str, ...] = (
        ".env",
        ".env.local",
        ".env.production",
        "credentials.json",
    )

    def resolve(self, relative_path: str) -> Path:
        candidate = (self.workspace / relative_path).resolve()
        workspace = self.workspace.resolve()
        try:
            candidate.relative_to(workspace)
        except ValueError as exc:
            raise PermissionError("Path escapes the SAGE workspace.") from exc
        return candidate

    def can_write(self, relative_path: str) -> bool:
        path = relative_path.replace("\\", "/").lstrip("/")
        if not path or path.startswith(".git/") or path == ".git":
            return False
        name = Path(path).name.lower()
        if name in {item.lower() for item in self.forbidden_names}:
            return False
        return any(path == root or path.startswith(root + "/") for root in self.writable_roots)

    def assert_write_allowed(self, relative_path: str) -> None:
        if not self.can_write(relative_path):
            raise PermissionError(f"Writing '{relative_path}' is not permitted by the agent policy.")

    def validate_check_command(self, command: str) -> list[str]:
        parts = shlex.split(command, posix=False)
        normalized = command.lower().replace("\\", "/")
        blocked = ("git push", "git reset", "git clean", "git checkout", "git branch -d", "rmdir", "del /s", "format ")
        if any(token in normalized for token in blocked):
            raise PermissionError("Destructive or remote Git/shell operation is not allowed.")
        allowed = {"python", "py", "pytest", "git"}
        if not parts or parts[0].lower().replace(".exe", "") not in allowed:
            raise PermissionError("Only approved development check commands are allowed.")
        return parts
