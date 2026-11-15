# Working rules (from handoff 2, section 0)

## How we work
- Simple English. Ask for ONE thing at a time. Claude cannot see my machine: only what I paste. Mark every check PASS / FAIL / NOT VERIFIED; never say PASS without pasted output.
- Label figures: stated in source (page) / my calculation / my inference. Never fill numbers from memory. Conflicts stay in the register.
- I write the paper myself. Explain: what the evidence says, what it does not establish, how to reproduce, which RQ.

## Safeguards
- Installed MW is not damaged MW; damaged is not unavailable; unavailable is not generation lost; estimated GWh is not observed; approved export capacity is not actual exports.
- Never add capacities across events. No causation from timing.
- No exportable power until all 4 inputs are known for the same period.

## Database changes
- Read-only preview, pg_dump backup (data/archive), ONE transaction with RAISE EXCEPTION checks, notes start [UNVERIFIED], verified = No.

## File changes
- Backup, Python patch that ABORTS unless the anchor is found exactly once, node --check, node --test tests/*.js, render in Edge, give an undo command.

## Commands
- Commands start with a cd line. Keep paste blocks SHORT. Run interactive commands (ssh-keygen, ssh) ALONE. Never put "exit" in a pasted block. Before "fixing a typo", grep the FILE: earlier "typos" were paste artefacts.
- Node 24 prints tests as "ℹ tests N".
- Narrow Edge error filter: grep -v -E 'chrome-extension://|chrome\\browser\\' err.txt | grep -ci error

## Two machines
- Git does not sync the database. After any DB change: re-dump to data/archive/nea_nepal_state_for_github.sql, commit, push. On the other machine: git pull, restore.
- Pull before work, push before leaving, never work on both at once.
- Clone with core.autocrlf=false. Never git add data/raw. Never push --force.
