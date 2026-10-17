from __future__ import annotations

import html
import re
import time
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from urllib.parse import urlparse

import httpx

from .safety import normalize_arabic

MEDLINEPLUS_SEARCH_URL = "https://wsearch.nlm.nih.gov/ws/query"
MEDLINEPLUS_ROOT = "medlineplus.gov"
CACHE_SECONDS = 12 * 60 * 60


@dataclass(frozen=True)
class Topic:
    slug: str
    label_ar: str
    search_term: str
    aliases: tuple[str, ...]


@dataclass(frozen=True)
class SourceRecord:
    title: str
    url: str
    summary: str
    publisher: str = "MedlinePlus / U.S. National Library of Medicine"


TOPICS: tuple[Topic, ...] = (
    Topic("asthma", "الربو", "asthma", ("الربو", "ربو", "asthma")),
    Topic("diabetes", "السكري", "diabetes", ("السكري", "السكر", "داء السكري", "diabetes")),
    Topic("blood-pressure", "ضغط الدم", "high blood pressure", ("ضغط الدم", "ارتفاع ضغط الدم", "high blood pressure")),
    Topic("anemia", "فقر الدم", "anemia", ("فقر الدم", "انيميا", "الانيميا", "anemia")),
    Topic("allergies", "الحساسية", "allergies", ("الحساسية", "الحساسيه", "allergies", "allergy")),
    Topic("cholesterol", "الكوليسترول", "cholesterol", ("الكوليسترول", "كوليسترول", "cholesterol")),
    Topic("arthritis", "التهاب المفاصل", "arthritis", ("التهاب المفاصل", "arthritis")),
    Topic("common-cold", "نزلات البرد", "common cold", ("نزلات البرد", "البرد", "common cold")),
    Topic("influenza", "الإنفلونزا", "influenza", ("الانفلونزا", "انفلونزا", "influenza", "flu")),
)


def match_topic(message: str) -> Topic | None:
    normalized = normalize_arabic(message)
    # Prefer longer aliases to avoid matching a short term inside an unrelated phrase.
    candidates = sorted(
        ((normalize_arabic(alias), topic) for topic in TOPICS for alias in topic.aliases),
        key=lambda item: len(item[0]),
        reverse=True,
    )
    for alias, topic in candidates:
        if alias and alias in normalized:
            return topic
    return None


def _clean_html(value: str) -> str:
    value = re.sub(r"(?is)<(script|style).*?>.*?</\1>", " ", value)
    value = re.sub(r"(?s)<[^>]+>", " ", value)
    value = html.unescape(value)
    return re.sub(r"\s+", " ", value).strip()


def _trusted_medlineplus_url(value: str) -> bool:
    parsed = urlparse(value)
    host = (parsed.hostname or "").lower()
    return parsed.scheme == "https" and (host == MEDLINEPLUS_ROOT or host.endswith("." + MEDLINEPLUS_ROOT))


def parse_medlineplus_xml(payload: bytes) -> list[SourceRecord]:
    root = ET.fromstring(payload)
    records: list[SourceRecord] = []
    for document in root.findall(".//document"):
        url = document.attrib.get("url", "").strip()
        if not _trusted_medlineplus_url(url):
            continue
        content_by_name = {
            item.attrib.get("name", ""): _clean_html("".join(item.itertext()))
            for item in document.findall("content")
        }
        title = content_by_name.get("title") or content_by_name.get("altTitle")
        summary = content_by_name.get("fullSummary") or content_by_name.get("snippet")
        if not title or not summary:
            continue
        records.append(SourceRecord(title=title[:180], url=url, summary=summary[:1800]))
    return records[:3]


class MedlinePlusClient:
    """Small NLM search client; it stores only mapped public topic results in memory."""

    def __init__(self, timeout_seconds: float = 8.0, client: httpx.AsyncClient | None = None):
        self._timeout_seconds = timeout_seconds
        self._client = client
        self._cache: dict[str, tuple[float, list[SourceRecord]]] = {}

    async def search(self, topic: Topic) -> list[SourceRecord]:
        now = time.monotonic()
        cached = self._cache.get(topic.slug)
        if cached and now - cached[0] < CACHE_SECONDS:
            return list(cached[1])

        own_client = self._client is None
        client = self._client or httpx.AsyncClient(timeout=self._timeout_seconds)
        try:
            response = await client.get(
                MEDLINEPLUS_SEARCH_URL,
                params={
                    "db": "healthTopics",
                    "term": topic.search_term,
                    "retmax": 3,
                    "rettype": "brief",
                    "tool": "sabahhealth",
                },
                headers={"Accept": "application/xml"},
            )
            response.raise_for_status()
            records = parse_medlineplus_xml(response.content)
            self._cache[topic.slug] = (now, records)
            return records
        finally:
            if own_client:
                await client.aclose()
