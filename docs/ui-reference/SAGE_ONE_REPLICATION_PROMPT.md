# Prompt: Continue SAGE ONE UI from this project

You are continuing an existing SAGE ONE React + TypeScript + Vite app. **Do not rebuild from scratch, switch frameworks, or delete existing work.** First inspect the project and read `SAGE_ONE_REPLICATION_BRIEF.md` and `IMPLEMENTATION_GAPS.md`.

Use `SAGE_ONE_MASTER_UI_REFERENCE.png` and the image under `src/imports/` as the visual source of truth. Replicate the exact SAGE orbit-S logo and wordmark, cosmic navy background, mountain/city night skyline, cyan-blue glows, typography, card shapes, spacing, icons, navigation, voice waveform/listening states, Spark/economy panels, and evolution badges/themes.

**Do not approximate assets.** Use the owner's original logo and background artwork. If an exact asset is missing, flag it and ask for it; don't substitute generic icons, emoji, stock images, or gradients. Do not invent missing evolution names, levels, thresholds, or benefits. The wider plan has 13 evolution themes, while current code has 10 rank entries; flag unresolved details.

Preserve existing components/routes. Keep mock values labeled as demo data. Inspect the real backend contract before API integration; never fake login, KYC, payment, voice, or AI success. Keep secrets out of Git. Work on a feature branch, not `main`; do not auto-merge.

Implement in phases: (1) logo/background/fonts/tokens; (2) Splash/Onboarding/Auth; (3) Home/navigation; (4) voice/chat; (5) remaining screens; (6) Evolution/Spark; (7) responsive polish. After each phase, run available checks and compare screenshots at the same viewport. Report actual changes/checks, remaining mismatches/assets, and the next single task. Keep `IMPLEMENTATION_GAPS.md` updated.