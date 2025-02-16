"""Test fixtures."""

import pytest
from app.main import app
from fastapi.testclient import TestClient


@pytest.fixture(scope="module")
def test_client() -> TestClient:
    """API test client.

    :return:
    """
    return TestClient(app)
