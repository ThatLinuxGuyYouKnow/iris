## Human-in-the-Loop Decision

**Iris never tells a student where to go — it tells them what's available and lets them decide.**

Route planning is the clearest example. Iris computes a path from Point A to Point B, weights it for accessibility, accounts for reported hazards, and speaks the route aloud. But it does not issue a command. The student hears the options, asks follow-up questions if needed, and makes the final call on which path to take.

This boundary exists for a reason. A routing algorithm works with incomplete information — GPS accuracy on campus can drift by 10–20 meters, a hazard report might be outdated, a path might be temporarily blocked by an event the system knows nothing about. If Iris said *"Go left now"* and the student followed blindly, a single error could mean walking into construction, down a staircase without a handrail, or into traffic. The stakes are physical, not informational.

By framing every route as a suggestion — *"I recommend this path, it avoids stairs, but there's a reported hazard at the junction"* — Iris keeps the student as the final decision-maker. The AI handles computation and interpretation. The human handles judgment.

## Responsible AI Guardrail

**Risk: Hallucinated directions causing physical harm.**

The most dangerous failure mode for Iris is fabrication. If the AI generates a description of a landmark, building name, or route that doesn't exist — and a visually impaired student acts on it — the consequence isn't a wrong answer on a screen. It's walking into an unsafe area, missing a critical service, or getting lost on a campus with construction zones and traffic.

This risk is amplified by the nature of the user. A sighted person can glance at a screen and immediately tell if an AI's output looks wrong. A visually impaired student relying on audio output has no visual cross-check. Over-reliance becomes life-threatening, not just inconvenient.

**Mitigation: Hardcoded anti-hallucination system prompts with verified fallbacks.**

Every AI call in Iris — vision narration, scene description, knowledge Q&A — carries a hardcoded system instruction: *never fabricate landmarks, signs, place names, or directions. If the image is unclear or the question cannot be answered from the knowledge bank, say so explicitly.*

When the AI can't provide a reliable answer, Iris degrades gracefully instead of guessing:

- Vision narration falls back to the nearest graph waypoint label (verified, not generated)
- Knowledge Q&A falls back to keyword search against the local knowledge bank
- Scene description falls back to GPS + reverse geocoding without camera interpretation
- If all inputs fail: *"I can't get a reading right now. Use the human-verified audio cue."*

Iris also frames every output as probabilistic, not definitive. The phrase *"you may qualify"* never becomes *"you qualify."* The phrase *"I recommend this path"* never becomes *"go this way."* This language boundary is enforced at the prompt level across all AI interactions, ensuring the student always understands that Iris is a tool for clarity, not a source of truth.
