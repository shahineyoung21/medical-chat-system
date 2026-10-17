import asyncio
import json

import httpx

from backend.app.provider import OpenAIAnswerGenerator, OpenAISettings
from backend.app.sources import SourceRecord, TOPICS


def test_provider_sends_only_allowlisted_topic_and_public_sources_with_store_false():
    captured = {}

    async def handler(request: httpx.Request) -> httpx.Response:
        captured["body"] = json.loads(request.content)
        captured["authorization"] = request.headers.get("Authorization")
        return httpx.Response(
            200,
            json={
                "output_text": "شرح عام من المصدر. هذه معلومات عامة وليست بديلًا عن الطبيب."
            },
        )

    async def run_test():
        client = httpx.AsyncClient(transport=httpx.MockTransport(handler))
        generator = OpenAIAnswerGenerator(
            OpenAISettings(api_key="test-key-not-real", model="test-model"),
            client=client,
        )
        try:
            return await generator.generate(
                TOPICS[0],
                [
                    SourceRecord(
                        "Asthma",
                        "https://medlineplus.gov/asthma.html",
                        "Synthetic excerpt.",
                    )
                ],
            )
        finally:
            await client.aclose()

    answer = asyncio.run(run_test())
    prompt = captured["body"]["input"]

    assert answer.startswith("شرح عام")
    assert captured["body"]["store"] is False
    assert captured["authorization"] == "Bearer test-key-not-real"
    assert "original message" in prompt
    assert "Synthetic excerpt." in prompt
    assert "patient@example.com" not in prompt
    assert "private_symptom_719" not in prompt


def test_provider_rejects_treatment_or_dose_in_model_output():
    async def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            json={"output_text": "تناول هذا الدواء يوميًا بجرعة ثابتة."},
        )

    async def run_test():
        client = httpx.AsyncClient(transport=httpx.MockTransport(handler))
        generator = OpenAIAnswerGenerator(
            OpenAISettings(api_key="test-key-not-real", model="test-model"),
            client=client,
        )
        try:
            try:
                await generator.generate(
                    TOPICS[0],
                    [
                        SourceRecord(
                            "Asthma",
                            "https://medlineplus.gov/asthma.html",
                            "Synthetic excerpt.",
                        )
                    ],
                )
            except ValueError as error:
                return error
            raise AssertionError("unsafe output was not rejected")
        finally:
            await client.aclose()

    asyncio.run(run_test())


def test_provider_rejects_personal_diagnostic_claim():
    async def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            json={"output_text": "أنت مصاب بالربو بالتأكيد."},
        )

    async def run_test():
        client = httpx.AsyncClient(transport=httpx.MockTransport(handler))
        generator = OpenAIAnswerGenerator(
            OpenAISettings(api_key="test-key-not-real", model="test-model"),
            client=client,
        )
        try:
            try:
                await generator.generate(
                    TOPICS[0],
                    [
                        SourceRecord(
                            "Asthma",
                            "https://medlineplus.gov/asthma.html",
                            "Synthetic excerpt.",
                        )
                    ],
                )
            except ValueError:
                return
            raise AssertionError("diagnostic output was not rejected")
        finally:
            await client.aclose()

    asyncio.run(run_test())
