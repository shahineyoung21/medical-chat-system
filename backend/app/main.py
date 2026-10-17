from __future__ import annotations

import os
from typing import Protocol

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, ConfigDict, Field

from .provider import OpenAIAnswerGenerator, OpenAISettings, UnsafeModelOutput
from .safety import classify_message
from .sources import MedlinePlusClient, SourceRecord, Topic, match_topic


class SourceClient(Protocol):
    async def search(self, topic: Topic) -> list[SourceRecord]: ...


class ChatRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")
    message: str = Field(min_length=1, max_length=1200)


class SourceItem(BaseModel):
    title: str
    url: str
    publisher: str


class ChatResponse(BaseModel):
    answer: str
    sources: list[SourceItem] = Field(default_factory=list)
    concern_detected: bool = False
    emergency: bool = False


EGYPTIAN_RESOURCES = [
    SourceItem(
        title="هيئة الإسعاف المصرية — 123",
        url="https://eao.gov.eg/",
        publisher="هيئة الإسعاف المصرية",
    ),
    SourceItem(
        title="وزارة الصحة والسكان المصرية",
        url="https://www.mohp.gov.eg/",
        publisher="وزارة الصحة والسكان المصرية",
    ),
    SourceItem(
        title="مستشفيات جامعة القاهرة",
        url="https://cu.edu.eg/page.php?pg=contentFront/SubSectionData.php&SubSectionId=199",
        publisher="جامعة القاهرة",
    ),
    SourceItem(
        title="الخدمات الصحية — جامعة عين شمس",
        url="https://www.asu.edu.eg/healthcare",
        publisher="جامعة عين شمس",
    ),
]


def _public_sources(records: list[SourceRecord]) -> list[SourceItem]:
    return [
        SourceItem(title=record.title, url=record.url, publisher=record.publisher)
        for record in records
    ]


def _configured_generator() -> OpenAIAnswerGenerator | None:
    settings = OpenAISettings.from_environment()
    if settings is None:
        return None
    return OpenAIAnswerGenerator(settings)


def create_app(
    source_client: SourceClient | None = None,
    answer_generator: OpenAIAnswerGenerator | None = None,
) -> FastAPI:
    app = FastAPI(
        title="Sabah Health Information API",
        version="0.1.0",
        description="Non-diagnostic, source-backed general health information prototype.",
    )
    app.state.source_client = source_client or MedlinePlusClient(
        timeout_seconds=float(os.getenv("SABAH_MEDLINEPLUS_TIMEOUT_SECONDS", "8"))
    )
    app.state.answer_generator = answer_generator if answer_generator is not None else _configured_generator()

    origins = [item.strip() for item in os.getenv("SABAH_CORS_ORIGINS", "").split(",") if item.strip()]
    if origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=origins,
            allow_credentials=False,
            allow_methods=["GET", "POST"],
            allow_headers=["Content-Type"],
        )

    @app.get("/health")
    async def health() -> dict[str, str]:
        return {
            "status": "ok",
            "mode": "openai" if app.state.answer_generator else "sources_only",
        }

    @app.get("/api/sources", response_model=list[SourceItem])
    async def sources() -> list[SourceItem]:
        return [
            SourceItem(
                title="MedlinePlus — معلومات صحية من المكتبة الوطنية للطب",
                url="https://medlineplus.gov/",
                publisher="U.S. National Library of Medicine",
            ),
            *EGYPTIAN_RESOURCES,
        ]

    @app.post("/api/chat", response_model=ChatResponse)
    async def chat(request: ChatRequest) -> ChatResponse:
        safety = classify_message(request.message)
        if safety.concern_detected:
            if safety.emergency:
                return ChatResponse(
                    answer=(
                        "إذا كانت هذه الحالة تحدث الآن، اتصل بالإسعاف المصري على 123 أو توجّه إلى أقرب طوارئ فورًا. "
                        "لا أستطيع تقييم الأعراض أو تشخيص سببها."
                    ),
                    sources=[EGYPTIAN_RESOURCES[0]],
                    concern_detected=True,
                    emergency=True,
                )
            return ChatResponse(
                answer=(
                    "لا أستطيع تقييم شكوى شخصية أو تأكيد وجود مرض أو اقتراح علاج. "
                    "يُرجى مناقشة الأعراض مع طبيب أو مختص صحي مؤهل. "
                    "إذا أصبحت الحالة طارئة، اتصل بالإسعاف المصري على 123."
                ),
                sources=[EGYPTIAN_RESOURCES[0]],
                concern_detected=True,
                emergency=False,
            )

        topic = match_topic(request.message)
        if topic is None:
            return ChatResponse(
                answer=(
                    "لا أجد موضوعًا عامًا مدعومًا في قائمة المصادر الحالية، لذلك لن أخمّن إجابة. "
                    "يمكنك السؤال بشكل عام عن الربو أو السكري أو ضغط الدم أو فقر الدم أو الحساسية أو الكوليسترول أو التهاب المفاصل أو نزلات البرد أو الإنفلونزا."
                ),
                sources=[],
            )

        try:
            records = await app.state.source_client.search(topic)
        except (httpx.HTTPError, ValueError):
            return ChatResponse(
                answer="تعذّر الوصول إلى المصدر الطبي الآن، لذلك لن أقدّم إجابة غير موثقة. حاول لاحقًا أو راجع المصادر الرسمية مباشرة.",
                sources=[],
            )

        if not records:
            return ChatResponse(
                answer="لم أجد مادة مناسبة في MedlinePlus لهذا الموضوع، لذلك لن أخمّن إجابة. يمكنك فتح صفحة MedlinePlus والبحث عن الموضوع مباشرة.",
                sources=[SourceItem(
                    title="MedlinePlus — المكتبة الوطنية للطب",
                    url="https://medlineplus.gov/",
                    publisher="U.S. National Library of Medicine",
                )],
            )

        answer_generator = app.state.answer_generator
        if answer_generator is None:
            answer = (
                "استُرجعت مواد من مصدر موثوق، لكن التلخيص العربي غير مفعّل على هذا الخادم. "
                "افتح المصدر الأصلي للاطلاع عليه. لا أريد اختراع ترجمة أو معلومات غير مدعومة."
            )
        else:
            try:
                answer = await answer_generator.generate(topic, records)
            except (httpx.HTTPError, UnsafeModelOutput, ValueError):
                answer = (
                    "تعذّر إنشاء ملخص عربي آمن من المصدر الآن. "
                    "يمكنك فتح صفحات المصدر الأصلية أدناه؛ لن أستبدلها بتخمين."
                )

        return ChatResponse(answer=answer, sources=_public_sources(records))

    return app


app = create_app()
