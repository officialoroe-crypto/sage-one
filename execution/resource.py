from __future__ import annotations

from dataclasses import dataclass
import os
import time


@dataclass(frozen=True)
class ResourceSnapshot:
    cpu_percent: float
    cpu_count: int
    memory_percent: float | None
    timestamp: float


class ResourceGuard:
    """Conservative local resource guard for SAGE execution workloads.

    The guard is dependency-free. CPU load uses the standard library when
    available; memory pressure is optional and intentionally best-effort.
    """

    def __init__(
        self,
        soft_cpu_percent: float = 50.0,
        hard_cpu_percent: float = 70.0,
        sample_interval: float = 0.15,
    ):
        if not 1 <= soft_cpu_percent <= 100:
            raise ValueError("soft_cpu_percent must be between 1 and 100")
        if not soft_cpu_percent < hard_cpu_percent <= 100:
            raise ValueError("hard_cpu_percent must be greater than soft_cpu_percent")
        if sample_interval < 0:
            raise ValueError("sample_interval cannot be negative")

        self.soft_cpu_percent = soft_cpu_percent
        self.hard_cpu_percent = hard_cpu_percent
        self.sample_interval = sample_interval

    def cpu_percent(self) -> float:
        """Return a short-window process-host CPU estimate."""
        if self.sample_interval == 0:
            return 0.0

        start = os.times()
        wall_start = time.perf_counter()
        time.sleep(self.sample_interval)
        end = os.times()
        wall_elapsed = max(time.perf_counter() - wall_start, 0.0001)

        cpu_seconds = (end.user - start.user) + (end.system - start.system)
        logical_cpus = max(os.cpu_count() or 1, 1)
        return max(0.0, min(100.0, (cpu_seconds / wall_elapsed) * 100.0 / logical_cpus))

    def snapshot(self) -> ResourceSnapshot:
        return ResourceSnapshot(
            cpu_percent=round(self.cpu_percent(), 2),
            cpu_count=os.cpu_count() or 1,
            memory_percent=None,
            timestamp=time.time(),
        )

    def allowed(self, snapshot: ResourceSnapshot | None = None) -> bool:
        current = snapshot or self.snapshot()
        return current.cpu_percent < self.hard_cpu_percent

    def should_throttle(self, snapshot: ResourceSnapshot | None = None) -> bool:
        current = snapshot or self.snapshot()
        return current.cpu_percent >= self.soft_cpu_percent

    def should_stop(self, snapshot: ResourceSnapshot | None = None) -> bool:
        current = snapshot or self.snapshot()
        return current.cpu_percent >= self.hard_cpu_percent


resource_guard = ResourceGuard()
