from execution.engine import ExecutionEngine
from execution.mode import ConnectivityState, ExecutionMode, ExecutionModeRouter, mode_router
from execution.policy import TaskClass, classify_task, local_execution_allowed
from execution.resource import ResourceBand, ResourceGuard, ResourceSnapshot, resource_guard
from execution.scheduler import ExecutionScheduler, ScheduledTask, scheduler

_execution_engine = None


def __getattr__(name):
    if name == "execution_engine":
        global _execution_engine
        if _execution_engine is None:
            _execution_engine = ExecutionEngine()
        return _execution_engine
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


__all__ = [
    "ConnectivityState",
    "ExecutionEngine",
    "ExecutionMode",
    "ExecutionModeRouter",
    "ExecutionScheduler",
    "ResourceBand",
    "ResourceGuard",
    "ResourceSnapshot",
    "ScheduledTask",
    "TaskClass",
    "classify_task",
    "execution_engine",
    "local_execution_allowed",
    "mode_router",
    "resource_guard",
    "scheduler",
]
