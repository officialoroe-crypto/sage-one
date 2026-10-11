# SAGE ONE — SAGE Spark Economy

Status: Owner decision recorded 2026-10-11. Implementation and financial rules require code audit before release.

## SAGE Spark Points (SP)
- Internal, non-cash app points. Visual identity: purple/silver mixed pattern.
- Initial grant: 100 SP to a new user, subject to account-abuse protections.
- Used for eligible in-app image generation, AI work, and other point-priced features.
- Cannot be exchanged for money, transferred as cash, or withdrawn to eSewa/banks.
- Tasks/achievements can award SP. Target: active users may earn around 50 SP daily through eligible tasks; this is a design target, not a guarantee or verified implementation.
- Server-verified, idempotent grants; audited ledger, rate limits, and anti-farming protections.
- Spending SP never reduces Evolution.

## SAGE Spark (SS)
- Separate gold/white earnings and redeemable-balance system.
- Intended to be earned through eligible work, sales, and verified earning activities; harder to earn than SP.
- Eligible SS may be paid out to eSewa or bank accounts only after provider, eligibility, fraud, compliance, and end-to-end payout requirements are verified.
- Do not promise cash value or successful payouts before verification.
- Owner mentioned a 500 SS charge for jobs and similar opportunities. Audit current flows before implementing: define who pays, what it buys, refunds/cancellations, and fraud protections. Do not apply it blindly to every job.
- No SP-to-SS conversion or exchange rate has been authorized.

## Evolution and achievements
- 13 ranks × 3 tiers = 39 states.
- Money-earned progression moves upward. Achievements may grant SP, not SS.
- Spending SP or SS cannot lower rank.
- Define the source of truth for money earned and rank thresholds; do not count SP, streaks, or unverified tasks as earnings.

## Required transaction safeguards
Inspect existing models/endpoints and migration paths first. Keep SP and SS in separate ledgers. Use server-side authorization, idempotent transactions, documented precision, non-negative balance enforcement, explicit holds/charges/refunds/payout states, user consent before paid actions, audit logs, fraud limits, and tests for duplicate/racing requests. Verify eSewa/bank integration before promising withdrawals.

## Open items to recover from code and prior decisions
- Exact scope and payer of 500 SS fee.
- Whether rank progression counts verified gross earnings, completed sales, or net settled payouts.
- Thresholds and refund/chargeback effects on lifetime progress.
- Daily SP quest values/caps and anti-abuse limits.
- SS payout minimums, fees, timing, verification, and provider status.
- Migration from any existing single Spark/XP balance.
