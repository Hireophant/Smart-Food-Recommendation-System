FOOD_CUES = ["món", "đặc sản", "ẩm thực", "food", "dish", "specialty"]


class SerpExtractor:

    @staticmethod
    def extract_snippets(raw_json: dict):
        """
        Trả về list snippet chứa từ khoá ẩm thực.
        Không tạo fallback, nếu không có gì thì trả list rỗng.
        """
        snippets = []

        for item in raw_json.get("organic_results", []):
            snip = (item.get("snippet") or "").lower()
            if any(cue in snip for cue in FOOD_CUES):
                snippets.append(snip)

        return snippets
