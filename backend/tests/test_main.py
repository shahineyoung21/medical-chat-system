import asyncio

import httpx

from backend.app.main import create_app
from backend.app.sources import SourceRecord, Topic


class FakeSourceClient:
    def __init__(self, records=None):
        self.records = records or [
            SourceRecord(
                title="Asthma",
                url="https://medlineplus.gov/asthma.html",
                summary="Synthetic public-source summary for testing.",
            )
        ]
        self.calls = []

    async def search(self, topic: Topic):
        self.calls.append(topic.slug)
        return self.records


class FakeAnswerGenerator:
    def __init__(self):
        self.calls = []

    async def generate(self, topic: Topic, sources: list[SourceRecord]) -> str:
        self.calls.append((topic.slug, len(sources)))
        return "ملخص تثقيفي اصطناعي مستند إلى المصدر، وليس تشخيصًا أو علاجًا."


def _post(app, path: str, payload: dict) -> httpx.Response:
    async def request():
        async with httpx.AsyncClient(
            transport=httpx.ASGITransport(app=app),
            base_url="http://test",
        ) as client:
            return await client.post(path, json=payload)

    return asyncio.run(request())


def test_general_topic_returns_source_and_grounded_answer():
    source_client = FakeSourceClient()
    generator = FakeAnswerGenerator()
    app = create_app(source_client, generator)

    response = _post(app, "/api/chat", {"message": "ما هو الربو؟"})

    assert response.status_code == 200
    data = response.json()
    assert "ملخص تثقيفي اصطناعي" in data["answer"]
    assert data["sources"][0]["url"] == "https://medlineplus.gov/asthma.html"
    assert data["concern_detected"] is False
    assert source_client.calls == ["asthma"]
    assert generator.calls == [("asthma", 1)]


def test_personal_symptom_is_escalated_without_retrieval_or_model():
    source_client = FakeSourceClient()
    generator = FakeAnswerGenerator()
    app = create_app(source_client, generator)

    response = _post(app, "/api/chat", {"message": "عندي صداع شديد"})

    assert response.status_code == 200
    data = response.json()
    assert data["concern_detected"] is True
    assert data["emergency"] is False
    assert "طبيب" in data["answer"]
    assert source_client.calls == []
    assert generator.calls == []


def test_emergency_uses_egyptian_ambulance_number_and_does_not_call_model():
    source_client = FakeSourceClient()
    generator = FakeAnswerGenerator()
    app = create_app(source_client, generator)

    response = _post(app, "/api/chat", {"message": "عندي ألم شديد في الصدر"})

    data = response.json()
    assert data["emergency"] is True
    assert data["concern_detected"] is True
    assert "123" in data["answer"]
    assert data["sources"][0]["url"] == "https://eao.gov.eg/"
    assert source_client.calls == []
    assert generator.calls == []


def test_unknown_topic_abstains_without_model_or_source_call():
    source_client = FakeSourceClient()
    generator = FakeAnswerGenerator()
    app = create_app(source_client, generator)

    response = _post(app, "/api/chat", {"message": "ما معنى موضوع غير مدعوم؟"})

    assert response.status_code == 200
    assert "لن أخمّن" in response.json()["answer"]
    assert source_client.calls == []
    assert generator.calls == []


def test_rejects_oversized_or_extra_input_fields():
    app = create_app(FakeSourceClient(), FakeAnswerGenerator())

    assert _post(app, "/api/chat", {"message": "س" * 1201}).status_code == 422
    assert _post(
        app,
        "/api/chat",
        {"message": "الربو", "history": ["خاص"]},
    ).status_code == 422


def test_personal_disease_statement_never_reaches_source_or_model():
    source_client = FakeSourceClient()
    generator = FakeAnswerGenerator()
    app = create_app(source_client, generator)

    response = _post(app, "/api/chat", {"message": "عندي ربو"})

    assert response.status_code == 200
    assert response.json()["concern_detected"] is True
    assert "طبيب" in response.json()["answer"]
    assert source_client.calls == []
    assert generator.calls == []
