# CalorAI Research Document (Extracted from uploaded Word report)

## Purpose
This document captures implementation guidance from the uploaded investigation report and should be treated as the product and technical research baseline for CalorAI.

## Core Product Direction
- Solve manual calorie logging friction with photo-first meal logging.
- Use local Malaysian food credibility as a differentiator by grounding nutrition with MyFCD.
- Keep user in control: show top suggestions, confidence, editable entries, and source transparency.
- Provide guided portion workflows (small/medium/large and gram-based custom input).
- Add recommendation support through chatbot and goal-based meal guidance.

## Similar-System Gaps to Address
- Existing western-centric apps have poor Malaysian dish coverage.
- Apps with image recognition often lack local verified nutrition grounding.
- Users need backup manual search when image recognition is uncertain.
- Users prefer multiple AI suggestions and confirmation before logging.

## Survey-Driven Requirements
- Photo logging with user confirmation is high priority.
- Malaysian food database breadth is top priority.
- Manual search fallback is mandatory.
- Confidence indicators and source labels are required for trust.
- Portion estimation support is essential.
- Users want recommendation help, especially healthier alternatives.

## Technical Direction from Report
- Flutter + Dart for cross-platform delivery and rapid UI iteration.
- Firebase Auth + Firestore for user data and meal logs.
- Gemini API for multimodal image understanding and chatbot responses.
- MyFCD as authoritative local reference; expand with additional validated references where needed.

## Recommended Build Priorities
1. Fast logging flow: capture photo -> top suggestions -> confirm/edit -> portion -> save.
2. Broad food coverage: MyFCD primary plus supplementary trusted datasets.
3. Trust UX: show source, confidence, and user correction path everywhere.
4. Personalized guidance: goal-aware recommendations and meal planning.
5. Performance and usability: keep meal logging under 30 seconds for common cases.

## Acceptance Signals from Research
- Users strongly prefer photo-based logging over full manual entry.
- Users strongly prefer source transparency and editability.
- Users strongly prefer Malaysian dish support and practical portion tools.
- Users show clear intent to adopt if logging is fast and localized.
