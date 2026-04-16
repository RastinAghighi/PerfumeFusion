import json
import os
import time
from google import genai

client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))

def get_description(name, brand):
    prompt = f'Describe the real-life perfume bottle of "{name}" by "{brand}" in exactly one sentence. Include only: bottle shape, glass color, cap material and color. No fragrance notes, no marketing text.'
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt
    )
    return response.text.strip()

def main():
    with open("data/perfumes_filtered.json", "r", encoding="utf-8") as f:
        perfumes = json.load(f)

    desc_path = "data/bottle_descriptions.json"
    if os.path.exists(desc_path):
        with open(desc_path, "r", encoding="utf-8") as f:
            descriptions = json.load(f)
    else:
        descriptions = {}

    total = len(perfumes)
    for i, p in enumerate(perfumes):
        key = p["name"]
        if key in descriptions:
            print(f"Skipping {key} (already done)")
            continue

        try:
            desc = get_description(p["name"], p["brand"])
            descriptions[key] = desc
            print(f"[{i+1}/{total}] {key}: {desc}")
        except Exception as e:
            print(f"[{i+1}/{total}] FAILED {key}: {e}")
            descriptions[key] = "Simple glass perfume bottle with a metallic cap."

        if (i + 1) % 10 == 0:
            with open(desc_path, "w", encoding="utf-8") as f:
                json.dump(descriptions, f, indent=2, ensure_ascii=False)
            print(f"--- Saved progress: {len(descriptions)}/{total} ---")

        time.sleep(6)

    with open(desc_path, "w", encoding="utf-8") as f:
        json.dump(descriptions, f, indent=2, ensure_ascii=False)
    print(f"Done! {len(descriptions)} descriptions saved.")

if __name__ == "__main__":
    main()
