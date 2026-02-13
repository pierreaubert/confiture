# Elves

**ELVES** (Endorsing Light Validity Evaluator System) is the protocol that governs **how parachain blocks are mathematically verified** across the entire network.

ELVES is the heart of Polkadot’s (and the upcoming JAM's) shared security model. Instead of having every single validator re-execute every single transaction (which fundamentally limits scalability), ELVES utilizes **Execution Sharding** via "Cynical Rollups."

It randomly selects a small **Audit Committee** to check a block. If *just one* honest node spots a lie, they trigger an **Escalation**—a full network audit where the malicious actors are heavily slashed.

## Simplified version

Run the Apalache model checker via the Quint CLI to verify the protocol:

```bash
quint verify elves.qnt --invariant no_invalid_finalization_inv
quint verify elves.qnt --invariant no_valid_rejection_inv
quint verify elves.qnt --invariant malicious_slashed_inv

```

Apalache will return `[ok] No violation found` for all three! But *why*?

### The Beauty of the "Pigeonhole Principle"

The true genius of ELVES relies on hypergeometric statistics. In our Quint model, there are **6 total validators**, and **2 are malicious**.

In `submit_block`, ELVES randomly selects **3 validators** to act as the fast-path audit committee. Because `3 > 2`, the mathematical pigeonhole principle dictates that **at least 1 auditor MUST be honest**.

That single honest auditor guarantees that an invalid block will be disputed. That dispute triggers an Escalation, expanding the `committee` to `VALIDATORS`. During the escalation, the network overwhelmingly proves the block is invalid, rejects it, and burns the staked tokens (`slashed`) of the attackers.

### Test the Vulnerability Yourself:

If you want to see Quint catch a network-breaking vulnerability, change the committee size constraint in the `submit_block` action:

```quint
nondet c = oneOf(VALIDATORS.powerset().filter(s => s.size() == 2)) // Change 3 to 2!

```

If you run `quint verify` again, **it will immediately fail**. It will output a trace showing a catastrophic scenario where both `M1` and `M2` are randomly selected to audit the block. Because there is no honest validator to raise a dispute, they unanimously approve an invalid block, bypassing ELVES entirely!

By correctly sizing the committee relative to the active validator set, Polkadot/JAM safely executes hundreds of parallel work-packages with the exact same security guarantees as if all 1,000 validators verified every single block.

## ELVES Model

### Parameters

┌────────────────────────┬──────────────┬──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│       Parameter        │    Value     │                                              Rationale                                               │
├────────────────────────┼──────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Validators             │ 10 (IDs 0–9) │ Manageable state space                                                                               │
├────────────────────────┼──────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Honest                 │ 7 (IDs 0–6)  │ >2/3 supermajority                                                                                   │
├────────────────────────┼──────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Malicious              │ 3 (IDs 7–9)  │ Standard 1/3 BFT bound                                                                               │
├────────────────────────┼──────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Cores                  │ 3            │ Parallel pipeline demo                                                                               │
├────────────────────────┼──────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Backing group size     │ 3 per core   │ Fixed partition: Core 0→{0,1,2}, Core 1→{3,4,5}, Core 2→{6,7,8}; validator 9 unassigned for approval │
├────────────────────────┼──────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Backing threshold      │ 2 of 3       │ Supermajority within group                                                                           │
├────────────────────────┼──────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Availability threshold │ 7 of 10      │ ⌈2/3 × 10⌉ + 1                                                                                       │
├────────────────────────┼──────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Approval tranches      │ 2            │ Minimal to show no-show escalation                                                                   │
├────────────────────────┼──────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Checkers per tranche   │ 2            │ Keeps state tractable                                                                                │
├────────────────────────┼──────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Dispute supermajority  │ 7 of 10      │ >2/3 to resolve                                                                                      │
├────────────────────────┼──────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Max candidates         │ 6            │ Bounds state for verification                                                                        │
└────────────────────────┴──────────────┴──────────────────────────────────────────────────────────────────────────────────────────────────────┘

### Types

CandidateStatus = Seconded | Backable | PendingAvailability | Available
                | ApprovalPending | Approved | Disputed | Finalized | Rejected

CandidateValidity = Valid | Invalid

Candidate = {
  id, core, validity (ground truth),
  status,
  backer_votes_for/against,
  availability_attestations,
  approval_assignments: int -> Set[ValidatorId],  // tranche -> checkers
  approval_votes_for/against,
  no_shows,
  current_tranche,
  dispute_votes_for/against
}

### State Variables

- candidates: CandidateId -> Candidate — per-candidate pipeline state (no global phase)
- backing_groups: CoreId -> Set[ValidatorId] — fixed at init
- next_candidate_id: int
- slashed: Set[ValidatorId]

### Pipeline (state transition diagram)

submit_candidate → [Seconded]
                      ↓ backing_vote ×2
                   [Backable]
                      ↓ include_candidate
              [PendingAvailability]
                      ↓ attest_availability ×7
                  [Available]
                      ↓ assign_approval_tranche(0)
              [ApprovalPending] ←── detect_no_show → next tranche
                   /       \
     approval_vote          dispute found
          ↓                      ↓
     [Approved]             [Disputed]
          ↓                   ↓ dispute_vote (all validators)
     [Finalized]          resolve_dispute
                          /           \
                   [Finalized]    [Rejected]
                   + slash         + slash
                   disputers       approvers

### Actions (12 total)

1. submit_candidate — nondet core (must be free) + nondet validity → Seconded
2. backing_vote(cid, v) — guard: v in backing group, not yet voted → adds to for/against; if threshold met → Backable
3. include_candidate(cid) — Backable → PendingAvailability
4. attest_availability(cid, v) — v attests chunk; if threshold met → Available → ApprovalPending
5. assign_approval_tranche(cid, tranche) — nondet select CHECKERS_PER_TRANCHE validators
6. approval_vote(cid, v) — assigned checker votes; if votes against → Disputed
7. detect_no_show(cid, v) — marks assigned checker as no-show; if all checked → next tranche
8. finalize_approval(cid) — enough approvals, no disputes → Finalized
9. initiate_dispute(cid) — approval votes against exist → Disputed
10. dispute_vote(cid, v) — any validator votes in dispute
11. resolve_dispute(cid) — supermajority reached → Finalized or Rejected + slash
12. idle — stuttering step when all candidates terminal

### Invariants (10)

┌─────┬──────────────────────────────────┬─────────────────────────────────────────┐
│  #  │               Name               │                Property                 │
├─────┼──────────────────────────────────┼─────────────────────────────────────────┤
│ 1   │ no_invalid_finalization_inv      │ Finalized ⟹ Valid (safety)              │
├─────┼──────────────────────────────────┼─────────────────────────────────────────┤
│ 2   │ no_valid_rejection_inv           │ Rejected ⟹ Invalid (liveness)           │
├─────┼──────────────────────────────────┼─────────────────────────────────────────┤
│ 3   │ malicious_slashed_inv            │ Rejected ⟹ at least 1 malicious slashed │
├─────┼──────────────────────────────────┼─────────────────────────────────────────┤
│ 4   │ backing_group_integrity_inv      │ Backing votes only from assigned group  │
├─────┼──────────────────────────────────┼─────────────────────────────────────────┤
│ 5   │ availability_threshold_inv       │ Available+ status ⟹ ≥7 attestations     │
├─────┼──────────────────────────────────┼─────────────────────────────────────────┤
│ 6   │ no_double_voting_inv             │ No validator in both for/against sets   │
├─────┼──────────────────────────────────┼─────────────────────────────────────────┤
│ 7   │ dispute_resolution_threshold_inv │ Resolution requires supermajority       │
├─────┼──────────────────────────────────┼─────────────────────────────────────────┤
│ 8   │ core_exclusivity_inv             │ At most 1 active candidate per core     │
├─────┼──────────────────────────────────┼─────────────────────────────────────────┤
│ 9   │ slashing_correctness_inv         │ Only incorrect voters are slashed       │
├─────┼──────────────────────────────────┼─────────────────────────────────────────┤
│ 10  │ noshow_escalation_inv            │ No-shows trigger next tranche           │
└─────┴──────────────────────────────────┴─────────────────────────────────────────┘

### Key design decisions

- Int IDs for validators (Quint can't generate random strings — matches JAM convention)
- Deterministic backing groups (fixed partition avoids combinatorial init explosion)
- Malicious always lie (worst-case adversary — sound for safety proofs)
- No time modeling (tranches are nondeterministic steps, not timed — sound overapproximation)
- No vote_log to keep state space small (slashing correctness checked structurally via candidate fields)

## Verification

### Verify each invariant individually
quint verify elves_v2.qnt --invariant no_invalid_finalization_inv
quint verify elves_v2.qnt --invariant no_valid_rejection_inv
quint verify elves_v2.qnt --invariant malicious_slashed_inv
quint verify elves_v2.qnt --invariant backing_group_integrity_inv
quint verify elves_v2.qnt --invariant availability_threshold_inv
quint verify elves_v2.qnt --invariant no_double_voting_inv
quint verify elves_v2.qnt --invariant core_exclusivity_inv

### Runtime sampling for quick feedback
quint run elves_v2.qnt --max-samples=10000 --max-steps=30 --invariant=no_invalid_finalization_inv

## Reference files

- elves/elves.qnt — original model, patterns to follow
- jam/confiture.qnt:295-434 — Dispute/Availability types for reference
- sassafras/sassafras.qnt — convention for standalone protocol modules
- beefy/beefy.qnt — threshold-based BFT modeling patterns
