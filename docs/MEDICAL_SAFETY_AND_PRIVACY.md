# Medical Safety and Privacy

## Safety Positioning

Inflamend is not a doctor. It does not diagnose, treat, prescribe, or replace clinician care. It helps users track self-reported data, notice possible patterns, and prepare for conversations with a GI clinician.

## Red Flags

The app should show calm urgent-care guidance for:

- Severe abdominal pain.
- Heavy bleeding or black/tarry stool.
- High fever.
- Fainting.
- Severe dehydration.
- Inability to keep fluids down.
- Chest pain.
- Shortness of breath.
- Rapid weight loss.
- Rapid worsening symptoms.
- Suicidal ideation or self-harm.

## Current Implementation

- Edge Function scaffolds include red-flag checks for AI and voice parsing.
- The database stores `safety_flags` on bowel logs and voice drafts.
- UI red-flag presentation is not implemented yet.

## Copy Rules

Use:

- "Possible pattern"
- "May be associated"
- "Not a diagnosis"
- "Keep logging to improve confidence"
- "Contact your clinician"

Avoid:

- "This caused your flare"
- "You should stop/start/change medication"
- "Your risk score means you will flare"
- "This is safe for everyone"
- "Emergency certainty"

## Privacy Positioning

- No ad tracking.
- No cross-app tracking.
- No sale/share of health data.
- AI memory is opt-in.
- Voice transcript storage is opt-in.
- Raw audio should not be stored.
- Account deletion and data export must be user-visible.
- Do not claim HIPAA compliance unless operational and legal requirements are actually in place.

## Required UI Work

- Add safety card component.
- Add red-flag detector in Swift with tests.
- Add disclaimer copy to AI/Care and report export flows.
- Add privacy controls for AI memory, transcript storage, export, and delete.
