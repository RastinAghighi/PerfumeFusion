# PerfumeFusion — Bottle Art Generation Guide

---

## Setup

1. Get your Gemini API key from https://aistudio.google.com/apikey
2. Install the dependency: `py -m pip install google-genai Pillow`
3. Set your API key: `$env:GEMINI_API_KEY = "your-key-here"`

---

## Step 1 — Generate Bottle Descriptions

This script reads your 200 perfumes and asks Gemini to describe each real bottle in one sentence.

/clear before running this prompt.

```
Create a Python script at scripts/tools/generate_descriptions.py

This script:
1. Reads data/perfumes_filtered.json
2. For each perfume, calls the Gemini API (model: gemini-2.5-flash) with this prompt:
   "Describe the real-life perfume bottle of [name] by [brand] in exactly one sentence. Include only: bottle shape, glass color, cap material and color. No fragrance notes, no marketing text. Example format: Tall rectangular dark red glass bottle with a rounded silver metallic cap."
3. Saves results to data/bottle_descriptions.json as a dictionary mapping perfume name to description
4. Adds a 6 second delay between each API call to avoid rate limits
5. Saves progress incrementally — writes to the JSON file after every 10 perfumes
6. If bottle_descriptions.json already exists, loads it and skips perfumes that already have descriptions (resume support)
7. Prints progress: "Described 10/200... Described 20/200..."
8. If an API call fails, log the error, skip that perfume, and continue

Use this code structure:

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

Windows PowerShell run command:
$env:GEMINI_API_KEY = "your-key-here"
cd C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion
py scripts/tools/generate_descriptions.py

Expected runtime: ~20 minutes (200 perfumes × 6 second delay)
```

**Verify:**
```powershell
py -c "import json; d=json.load(open('data/bottle_descriptions.json')); print(len(d), 'descriptions'); print(list(d.items())[:3])"
```

```powershell
git add .
git commit -m "Generate bottle descriptions for all 200 perfumes"
git push
```

---

## Step 2 — Generate Bottle Images

This script takes the descriptions and generates a cartoon game sprite for each bottle.

/clear before running this prompt.

```
Create a Python script at scripts/tools/generate_bottles.py

This script:
1. Reads data/perfumes_filtered.json and data/bottle_descriptions.json
2. Creates the output folder: assets/art/bottles/
3. For each perfume, calls the Gemini API image generation with this prompt template:

   "Generate a cute cartoon game sprite of a perfume bottle. {bottle_description}. Chibi/kawaii game art style, flat shading, clean dark outlines, slight glow effect. Transparent background. 128x128 pixel size. No text, no labels, no watermarks."

4. Saves the generated image as assets/art/bottles/{perfume_name}.png
5. Adds a 10 second delay between each API call (image generation is heavier than text)
6. Resume support: if the .png file already exists, skip that perfume
7. Prints progress: "Generated 10/200... Generated 20/200..."
8. If an API call fails, log the error, skip that perfume, add it to a failed list
9. At the end, save failed perfumes to data/failed_bottles.json for retry

Use this code structure:

import json
import os
import time
import base64
from google import genai
from google.genai import types

client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))

def generate_bottle_image(description, output_path):
    prompt = f"Generate a cute cartoon game sprite of a perfume bottle. {description}. Chibi/kawaii game art style, flat shading, clean dark outlines, slight glow effect. Transparent background. 128x128 pixel size. No text, no labels, no watermarks."

    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt,
        config=types.GenerateContentConfig(
            response_modalities=["IMAGE", "TEXT"],
        )
    )

    for part in response.candidates[0].content.parts:
        if part.inline_data is not None:
            image_data = part.inline_data.data
            with open(output_path, "wb") as f:
                f.write(base64.b64decode(image_data) if isinstance(image_data, str) else image_data)
            return True
    return False

def main():
    with open("data/perfumes_filtered.json", "r", encoding="utf-8") as f:
        perfumes = json.load(f)

    with open("data/bottle_descriptions.json", "r", encoding="utf-8") as f:
        descriptions = json.load(f)

    os.makedirs("assets/art/bottles", exist_ok=True)

    failed = []
    total = len(perfumes)

    for i, p in enumerate(perfumes):
        name = p["name"]
        output_path = f"assets/art/bottles/{name}.png"

        if os.path.exists(output_path):
            print(f"Skipping {name} (already exists)")
            continue

        desc = descriptions.get(name, "Simple glass perfume bottle with a metallic cap.")

        try:
            success = generate_bottle_image(desc, output_path)
            if success:
                print(f"[{i+1}/{total}] Generated: {name}")
            else:
                print(f"[{i+1}/{total}] No image returned: {name}")
                failed.append(name)
        except Exception as e:
            print(f"[{i+1}/{total}] FAILED {name}: {e}")
            failed.append(name)

        time.sleep(10)

    if failed:
        with open("data/failed_bottles.json", "w", encoding="utf-8") as f:
            json.dump(failed, f, indent=2)
        print(f"\n{len(failed)} bottles failed. Saved to data/failed_bottles.json")

    print(f"\nDone! Check assets/art/bottles/ for {total - len(failed)} images.")

if __name__ == "__main__":
    main()

Windows PowerShell run command:
$env:GEMINI_API_KEY = "your-key-here"
cd C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion
py scripts/tools/generate_bottles.py

Expected runtime: ~35 minutes (200 perfumes × 10 second delay)
```

**Verify:**
```powershell
(ls assets/art/bottles/*.png).Count
```
Should show close to 200.

```powershell
git add .
git commit -m "Generate bottle art for all perfumes"
git push
```

---

## Step 3 — Retry Failed Bottles

If some bottles failed, run this after /clear:

```
Create a Python script at scripts/tools/retry_bottles.py

This script:
1. Reads data/failed_bottles.json
2. Reads data/bottle_descriptions.json
3. Retries generating each failed bottle with a longer 15 second delay
4. Uses the same prompt template and output path as generate_bottles.py
5. If a bottle fails again, use a generic fallback description: "Simple elegant glass perfume bottle with a metallic cap"
6. Prints progress and results

Run command:
$env:GEMINI_API_KEY = "your-key-here"
py scripts/tools/retry_bottles.py
```

---

## Step 4 — Generate Opponent Character Art

After bottles are done, we generate the 20 opponent portraits.

/clear before running this prompt.

```
Create a Python script at scripts/tools/generate_opponents.py

This script:
1. Reads data/opponents.json
2. Creates output folder: assets/art/opponents/
3. For each opponent, generates a character portrait using Gemini API with this prompt:

   For example, opponent "Gym Bro Gary" with title "The Muscle":
   "Generate a cute cartoon character portrait for a mobile game. A muscular gym bro character who loves cologne. Funny, exaggerated features, chibi/kawaii style. Confident smirk expression. Upper body portrait, facing forward. Clean dark outlines, flat shading, vibrant colors. Transparent background. 256x256 pixels. No text."

   Build the prompt dynamically from the opponent's name, title, and description.

4. Saves as assets/art/opponents/{opponent_id}_{name_slug}.png
5. 10 second delay between requests
6. Resume support: skip if file exists
7. Log failures to data/failed_opponents.json

The prompt template for each opponent:
"Generate a cute cartoon character portrait for a mobile game. A character named {name}, known as {title}. {description}. Funny, exaggerated features, chibi/kawaii game art style. Upper body portrait, facing forward. Clean dark outlines, flat shading, vibrant colors. Transparent background. 256x256 pixels. No text, no labels."

Run command:
$env:GEMINI_API_KEY = "your-key-here"
py scripts/tools/generate_opponents.py

Expected runtime: ~4 minutes (20 opponents × 10 second delay)
```

**Verify:**
```powershell
(ls assets/art/opponents/*.png).Count
```
Should show 20.

```powershell
git add .
git commit -m "Generate opponent character portraits"
git push
```

---

## Overnight Plan

Run these in order, then walk away:

```powershell
$env:GEMINI_API_KEY = "your-key-here"
cd "C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion"
py scripts/tools/generate_descriptions.py
py scripts/tools/generate_bottles.py
py scripts/tools/generate_opponents.py
```

Total runtime: ~60 minutes. Come back and review 220 images.
