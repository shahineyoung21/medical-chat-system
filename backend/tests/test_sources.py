from backend.app.sources import match_topic, parse_medlineplus_xml


def test_arabic_topic_maps_to_allowlisted_english_query():
    assert match_topic("من فضلك اشرح ضغط الدم") .search_term == "high blood pressure"
    assert match_topic("هل الربو معدٍ؟").slug == "asthma"


def test_unknown_topic_does_not_produce_search_term():
    assert match_topic("ما معنى عرض غريب غير مدعوم؟") is None


def test_parser_extracts_source_and_strips_markup_and_rejects_offsite_url():
    xml = b'''<nlmSearchResult><list>
      <document url="https://medlineplus.gov/asthma.html" rank="0">
        <content name="title">Asthma</content>
        <content name="fullSummary">&lt;p&gt;A general &lt;b&gt;topic&lt;/b&gt; summary.&lt;/p&gt;</content>
      </document>
      <document url="https://evil.example/asthma" rank="1">
        <content name="title">Bad</content>
        <content name="fullSummary">Do not use.</content>
      </document>
    </list></nlmSearchResult>'''

    records = parse_medlineplus_xml(xml)

    assert len(records) == 1
    assert records[0].title == "Asthma"
    assert records[0].summary == "A general topic summary."
    assert records[0].url == "https://medlineplus.gov/asthma.html"
