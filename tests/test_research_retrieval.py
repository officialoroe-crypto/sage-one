import json
from urllib.parse import quote

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def _tool_request(name: str, arguments: dict):
    encoded = quote(json.dumps(arguments, separators=(",", ":")))
    return client.post(f"/tools/execute?tool_name={name}&arguments={encoded}")


def test_research_list_tool_is_exposed():
    response = client.get("/tools")
    assert response.status_code == 200
    tools = response.json()["tools"]
    names = {tool["name"] for tool in tools}
    assert "research_list" in names
    assert "research_get" in names
    assert "research_by_task" in names


def test_research_list_tool_accepts_json_arguments():
    response = _tool_request("research_list", {"limit": 5})
    assert response.status_code == 200
    payload = response.json()
    assert payload["success"] is True
    assert isinstance(payload["result"], list)


def test_missing_research_record_returns_null():
    response = _tool_request(
        "research_get",
        {"research_id": "does-not-exist"},
    )
    assert response.status_code == 200
    assert response.json()["result"] is None
