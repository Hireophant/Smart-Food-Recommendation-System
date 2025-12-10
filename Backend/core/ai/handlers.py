import os
import aiohttp
import json
from utils import Logger
from core.ai.schemas import AIKeywordRefineInput, AIKeywordRefineOutput


class AIKeywordRefineHandler:
    """
    CORE AI Handler:
    - Gửi dữ liệu đến OpenAI/Gemini
    - Không mock
    - Không fallback
    - Nếu lỗi → raise Exception
    """

    def __init__(self):
        self.api_key = os.getenv("OPENAI_API_KEY")
        if not self.api_key:
            raise RuntimeError("OPENAI_API_KEY is not set.")

        self.url = "https://api.openai.com/v1/chat/completions"  # hoặc Gemini URL nếu bạn dùng Gemini

    async def RefineKeywords(self, data: AIKeywordRefineInput) -> AIKeywordRefineOutput:
        """
        AI chịu trách nhiệm trích danh sách món ăn.
        Output phải là JSON array.
        """

        prompt = (
            "Dựa vào các đoạn văn sau, trích ra danh sách các món ăn, đặc sản "
            "được nhắc đến. Chỉ trả output theo dạng JSON array, ví dụ:\n"
            "[\"kẹo dừa\", \"chuối đập nướng\"]\n"
            "Không thêm giải thích.\n\n"
            f"Snippets:\n{data.content['snippets']}"
        )

        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.api_key}",
        }

        payload = {
            "model": "gpt-4o-mini",     # hoặc model bạn dùng
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.0
        }

        async with aiohttp.ClientSession() as session:
            async with session.post(self.url, json=payload, headers=headers) as resp:
                if resp.status != 200:
                    detail = await resp.text()
                    raise RuntimeError(f"AI API error: {resp.status} → {detail}")

                raw = await resp.json()

        # ─── Parse JSON from AI ───
        try:
            text = raw["choices"][0]["message"]["content"].strip()
            keywords = json.loads(text)
            if not isinstance(keywords, list):
                raise ValueError("AI output is not a list.")
        except Exception as e:
            raise RuntimeError(f"AI keyword parsing error: {e}")

        return AIKeywordRefineOutput(keywords=keywords)
