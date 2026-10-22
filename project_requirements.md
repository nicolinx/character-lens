# Product Requirements Document (PRD): Character Lens

## 1. Project Overview
**Character Lens** is a Flutter-based utility application designed to help users identify, translate, and understand non-Latin characters (such as Hanzi, Kanji, Hanja, or Arabic) by drawing them directly on their device screen. 

### 1.1 Study Case & Target Audience
*   **Target Audience:** Language learners, travelers, and linguistics enthusiasts.
*   **Problem Statement:** Users frequently encounter foreign characters in daily life (signs, menus, textbooks) but cannot type them into standard translation apps because they do not know the phonetic spelling (e.g., Pinyin or Romaji).
*   **Solution:** A handwriting recognition tool that translates manual strokes into digital characters, providing pronunciation, meaning, and cross-language etymological connections.

---

## 2. Core Features (Functional Requirements)

### 2.1 Language Selector
*   **Description:** A segmented control or horizontal list allowing users to select the target language before drawing.
*   **Options (MVP):** AR (Arabic), CN (Chinese - Hanzi), KO (Korean - Hanja), HI (Hindi).
*   **Behavior:** Selecting a language updates the underlying Machine Learning recognition model.

### 2.2 Smart Drawing Canvas
*   **Description:** An interactive drawing board with a grid background (similar to character practice sheets) to guide stroke proportions.
*   **Features:**
    *   Real-time stroke rendering.
    *   **Clear Button:** Clears the canvas instantly.
    *   **Status Indicator:** Displays text such as "Ready for input" or "Analyzing...".

### 2.3 Analysis Trigger ("Analyze" Button)
*   **Description:** A primary Call-to-Action (CTA) button that initiates the recognition process.
*   **Behavior:** Disables user input on the canvas and shows a loading state (e.g., shimmer or spinner) while fetching data.

### 2.4 Result Modal (Bottom Sheet)
*   **Description:** A smooth, modal bottom sheet that appears upon successful analysis.
*   **Components:**
    *   **Primary Character:** The recognized digital character (e.g., "木").
    *   **Language Tag:** e.g., "CHINESE (HANZI)".
    *   **Audio Button (TTS):** Plays the native pronunciation of the character.
    *   **Details Card:** Displays "Pinyin/Romaji" and "Meaning" (e.g., Pinyin: *mù*, Meaning: *Tree, Wood*).

### 2.5 Cross-Language Matches
*   **Description:** A specialized section inside the Result Modal showing equivalent characters in other languages that share the same historical root.
*   **Example:** If the user draws the Chinese "木" (mù), it displays the Japanese Kanji "ki" (Tree) and Korean Hanja "mok" (Tree).

---

## 3. Technical Requirements

### 3.1 Frontend (Mobile App)
*   **Framework:** Flutter (Dart).
*   **UI/UX:** Clean, minimalist design. Use `CustomPaint` or a drawing package (e.g., `signature`) for the canvas. Modal transitions must be smooth.
*   **State Management:** BLoC or Riverpod for predictable state flow (essential for handling loading/success/error states during API calls).

### 3.2 AI & Integrations
*   **Handwriting Recognition:** Google ML Kit (Digital Ink Recognition API). Must process strokes offline for speed and privacy.
*   **Context & Dictionary API:** 
    *   *Option A (LLM):* OpenAI API or Gemini API to fetch meaning, phonetic spelling, and cross-language matches dynamically via a structured JSON prompt.
    *   *Option B (Traditional):* Free Dictionary APIs (e.g., Jisho API, CC-CEDICT).
*   **Text-to-Speech (TTS):** `flutter_tts` package utilizing the device's native TTS engines (iOS/Android).

### 3.3 Security
*   **API Keys:** All sensitive keys (LLM/Dictionary API) MUST be stored in a `.env` file using the `flutter_dotenv` package and excluded from version control (`.gitignore`).

---

## 4. System Flow
1. User selects the target language (e.g., CN).
2. User draws the character on the canvas.
3. User taps "Analyze".
4. App captures stroke coordinates and passes them to **Google ML Kit (Digital Ink)**.
5. ML Kit returns the most likely digital string (e.g., "木").
6. App sends the string to the **Dictionary API / LLM backend**.
7. Backend returns a JSON object containing Pinyin, Meaning, and Cross-Language Matches.
8. App renders the data in the Bottom Sheet.
9. User taps the Audio icon; App triggers native **TTS** to speak the character.

---

## 5. Future Enhancements (Post-MVP)
*   **Stroke Order Validation:** Educating users if they drew the character using the incorrect stroke order.
*   **History & Bookmarks:** Saving previously searched characters for later study.
*   **Camera Integration (OCR):** Allowing users to snap a picture instead of drawing.