from typing import List

from core.serp.handlers import SerpHandler
from core.serp.extractors import SerpExtractor
from core.ai.handlers import AIKeywordRefineHandler
from core.ai.schemas import AIKeywordRefineInput


async def get_keywords_from_query(query: str) -> List[str]:
    """
    Nhận query → SERP → extract snippet → AI → keywords
    Không mock, không fallback, không dữ liệu ảo.
    """

    serp = SerpHandler()
    ai = AIKeywordRefineHandler()

    # Step 1: Fetch SERP data
    raw_json = await serp.search(query)

    # Step 2: Extract relevant snippets
    snippets = SerpExtractor.extract_snippets(raw_json)

    # Nếu không có snippet → trả list rỗng
    if not snippets:
        return []

    # Step 3: call AI
    ai_input = AIKeywordRefineInput(content={"snippets": snippets})
    ai_output = await ai.RefineKeywords(ai_input)

    return ai_output.keywords

