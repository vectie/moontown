# Synthetic standing-goal outlook example

These exact retained inputs and outputs come from the native executable verifier.
The baseline extends the existing canonical goal-table fixture with a market goal.
The CSV edit changes only the customer cadence 60 to 120 and due tick 240 to 270.
Reimport through goal_table creates candidate.json. Over [240,600), projected
occurrences change 10 to 7 and shared ticks 2 to 1. These are cadence-only local
scenarios, not real user state or actual daemon runs. See docs/GOAL_OUTLOOK.md.
