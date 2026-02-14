//                                                                          -*- quint -*-

module grandpa {
  // --- TYPES & CONSTANTS ---
  type Validator = int
  type Block = { hash: int, parent: int, height: int }
  type Vote = { voter: Validator, round: int, block_hash: int, kind: str }

  pure val HONEST: Set[Validator] = Set(1, 2, 3)
  pure val MALICIOUS: Set[Validator] = Set(4)
  pure val VALIDATORS: Set[Validator] = HONEST.union(MALICIOUS)

  pure val THRESHOLD: int = 3   // 2f+1 for N=4
  pure val NUM_ROUNDS: int = 3

  // Static block tree (pre-defined DAG)
  //        0 (genesis, h=0)
  //       / \
  //      1   2   (h=1)
  //      |   |
  //      3   4   (h=2)
  //      |
  //      5       (h=3)
  // Chain A: 0→1→3→5, Chain B: 0→2→4. Fork at height 1.
  pure val BLOCKS: int -> Block = Map(
    0 -> { hash: 0, parent: 0, height: 0 },
    1 -> { hash: 1, parent: 0, height: 1 },
    2 -> { hash: 2, parent: 0, height: 1 },
    3 -> { hash: 3, parent: 1, height: 2 },
    4 -> { hash: 4, parent: 2, height: 2 },
    5 -> { hash: 5, parent: 3, height: 3 }
  )

  pure val ALL_BLOCKS: Set[int] = Set(0, 1, 2, 3, 4, 5)

  // --- STATE VARIABLES (7 total, same pattern as BEEFY) ---
  var phase: str                              // "PREVOTE", "PRECOMMIT", "FINALIZE", "SLASH", "DONE"
  var current_round: int                      // 1..NUM_ROUNDS
  var votes: Set[Vote]                        // all votes across all rounds (persists)
  var finalized: Set[int]                     // set of finalized block hashes (genesis always included)
  var equivocations_detected: Set[Validator]  // validators caught equivocating
  var slashed: Set[Validator]                 // validators removed from active set
  var online: Set[Validator]                  // validators currently online

  // --- HELPER FUNCTIONS ---

  // Walk up the tree to check ancestry (4 unrolled steps, covers max height 3)
  pure def is_ancestor(target: int, block: int): bool = {
    val steps = Set(0, 1, 2, 3)
    val final_pos = steps.fold(block, (curr, _step) =>
      if (curr == target) curr else BLOCKS.get(curr).parent
    )
    final_pos == target
  }

  // Voters for a block counting descendants (GHOST semantics)
  pure def voters_for(target: int, r: int, k: str, vs: Set[Vote]): Set[Validator] =
    vs.filter(v => v.kind == k and v.round == r and is_ancestor(target, v.block_hash))
      .map(v => v.voter)

  // Count unique voters for a block and all its descendants
  pure def count_votes_for(target: int, r: int, k: str, vs: Set[Vote]): int =
    voters_for(target, r, k, vs).size()

  // GHOST rule: highest block with >= THRESHOLD prevotes
  pure def ghost_candidate(r: int, vs: Set[Vote]): int =
    ALL_BLOCKS.fold(0, (best, b) =>
      if (count_votes_for(b, r, "prevote", vs) >= THRESHOLD
          and BLOCKS.get(b).height > BLOCKS.get(best).height) b
      else best
    )

  // Equivocation: voted for two different blocks with same kind in same round
  pure def has_equivocated(vs: Set[Vote], v: Validator): bool =
    vs.exists(v1 =>
      vs.exists(v2 =>
        v1.voter == v and v2.voter == v
        and v1.round == v2.round
        and v1.kind == v2.kind
        and v1.block_hash != v2.block_hash
      )
    )

  // All ancestors of a block (inclusive), used for transitive finalization
  pure def ancestors_of(b: int): Set[int] = {
    val a0 = b
    val a1 = BLOCKS.get(a0).parent
    val a2 = BLOCKS.get(a1).parent
    val a3 = BLOCKS.get(a2).parent
    Set(a0, a1, a2, a3)
  }

  // Highest finalized block (used to constrain honest prevotes)
  pure def highest_finalized(fin: Set[int]): int =
    fin.fold(0, (best, b) =>
      if (BLOCKS.get(b).height > BLOCKS.get(best).height) b else best
    )

  // --- INITIALIZATION ---
  action init = all {
    phase' = "PREVOTE",
    current_round' = 1,
    votes' = Set(),
    finalized' = Set(0),
    equivocations_detected' = Set(),
    slashed' = Set(),
    online' = VALIDATORS,
  }

  // --- ACTIONS (STATE TRANSITIONS) ---

  // Phase A — Honest validator prevotes for a block extending highest finalized
  action cast_honest_prevote = {
    nondet v = HONEST.oneOf()
    nondet b = ALL_BLOCKS.oneOf()
    all {
      phase == "PREVOTE",
      online.contains(v),
      not(slashed.contains(v)),
      // Only one prevote per validator per round
      not(votes.exists(vote => vote.voter == v and vote.round == current_round and vote.kind == "prevote")),
      // Must extend highest finalized chain
      is_ancestor(highest_finalized(finalized), b),
      votes' = votes.union(Set({ voter: v, round: current_round, block_hash: b, kind: "prevote" })),
      phase' = phase,
      current_round' = current_round,
      finalized' = finalized,
      equivocations_detected' = equivocations_detected,
      slashed' = slashed,
      online' = online,
    }
  }

  // Phase A — Malicious validator prevotes for any block (can equivocate)
  action cast_malicious_prevote = {
    nondet v = MALICIOUS.oneOf()
    nondet b = ALL_BLOCKS.oneOf()
    all {
      phase == "PREVOTE",
      online.contains(v),
      not(slashed.contains(v)),
      // No uniqueness guard — can prevote for multiple blocks
      votes' = votes.union(Set({ voter: v, round: current_round, block_hash: b, kind: "prevote" })),
      phase' = phase,
      current_round' = current_round,
      finalized' = finalized,
      equivocations_detected' = equivocations_detected,
      slashed' = slashed,
      online' = online,
    }
  }

  // Phase B — End prevoting: nondeterministic transition
  action end_prevoting = all {
    phase == "PREVOTE",
    phase' = "PRECOMMIT",
    current_round' = current_round,
    votes' = votes,
    finalized' = finalized,
    equivocations_detected' = equivocations_detected,
    slashed' = slashed,
    online' = online,
  }

  // Phase C — Honest validator precommits for GHOST candidate
  action cast_honest_precommit = {
    nondet v = HONEST.oneOf()
    val candidate = ghost_candidate(current_round, votes)
    all {
      phase == "PRECOMMIT",
      online.contains(v),
      not(slashed.contains(v)),
      // Only one precommit per validator per round
      not(votes.exists(vote => vote.voter == v and vote.round == current_round and vote.kind == "precommit")),
      votes' = votes.union(Set({ voter: v, round: current_round, block_hash: candidate, kind: "precommit" })),
      phase' = phase,
      current_round' = current_round,
      finalized' = finalized,
      equivocations_detected' = equivocations_detected,
      slashed' = slashed,
      online' = online,
    }
  }

  // Phase C — Malicious validator precommits for any block (can equivocate)
  action cast_malicious_precommit = {
    nondet v = MALICIOUS.oneOf()
    nondet b = ALL_BLOCKS.oneOf()
    all {
      phase == "PRECOMMIT",
      online.contains(v),
      not(slashed.contains(v)),
      // No uniqueness guard — can precommit for multiple blocks
      votes' = votes.union(Set({ voter: v, round: current_round, block_hash: b, kind: "precommit" })),
      phase' = phase,
      current_round' = current_round,
      finalized' = finalized,
      equivocations_detected' = equivocations_detected,
      slashed' = slashed,
      online' = online,
    }
  }

  // Phase D — End precommitting: nondeterministic transition
  action end_precommitting = all {
    phase == "PRECOMMIT",
    phase' = "FINALIZE",
    current_round' = current_round,
    votes' = votes,
    finalized' = finalized,
    equivocations_detected' = equivocations_detected,
    slashed' = slashed,
    online' = online,
  }

  // Phase E — Try to finalize a block with >= THRESHOLD precommits
  action try_finalize = {
    nondet b = ALL_BLOCKS.oneOf()
    all {
      phase == "FINALIZE",
      count_votes_for(b, current_round, "precommit", votes) >= THRESHOLD,
      finalized' = finalized.union(ancestors_of(b)),
      phase' = "SLASH",
      current_round' = current_round,
      votes' = votes,
      equivocations_detected' = equivocations_detected,
      slashed' = slashed,
      online' = online,
    }
  }

  // Phase E — No block has threshold precommits, skip
  action skip_finalize = all {
    phase == "FINALIZE",
    ALL_BLOCKS.forall(b => count_votes_for(b, current_round, "precommit", votes) < THRESHOLD),
    phase' = "SLASH",
    current_round' = current_round,
    votes' = votes,
    finalized' = finalized,
    equivocations_detected' = equivocations_detected,
    slashed' = slashed,
    online' = online,
  }

  // Phase F — Detect equivocators, slash them, advance round
  action slash_and_advance = {
    val new_equivocators = VALIDATORS.filter(v => has_equivocated(votes, v))
    nondet next_online = VALIDATORS.powerset().oneOf()
    all {
      phase == "SLASH",
      equivocations_detected' = new_equivocators,
      slashed' = slashed.union(new_equivocators),
      online' = next_online,
      current_round' = current_round + 1,
      phase' = if (current_round >= NUM_ROUNDS) "DONE" else "PREVOTE",
      votes' = votes,
      finalized' = finalized,
    }
  }

  // Idle (stuttering step) — prevents deadlock after all rounds complete
  action idle = all {
    phase == "DONE",
    phase' = phase,
    current_round' = current_round,
    votes' = votes,
    finalized' = finalized,
    equivocations_detected' = equivocations_detected,
    slashed' = slashed,
    online' = online,
  }

  // --- STATE TRANSITIONS ---
  action step = any {
    cast_honest_prevote,
    cast_malicious_prevote,
    end_prevoting,
    cast_honest_precommit,
    cast_malicious_precommit,
    end_precommitting,
    try_finalize,
    skip_finalize,
    slash_and_advance,
    idle,
  }

  // ==========================================
  // --- INVARIANTS (CORRECTNESS PROPERTIES) ---
  // ==========================================

  // Safety: No two finalized blocks at the same height (no forks)
  val safety_inv =
    finalized.forall(b1 =>
      finalized.forall(b2 =>
        (BLOCKS.get(b1).height == BLOCKS.get(b2).height) implies (b1 == b2)
      )
    )

  // Justification: Every finalized block (except genesis) has its parent finalized
  val justification_inv =
    finalized.forall(b =>
      b == 0 or finalized.contains(BLOCKS.get(b).parent)
    )

  // Honest validators never vote for conflicting blocks (same kind, same round)
  val honest_no_equivocation_inv =
    HONEST.forall(h => not(has_equivocated(votes, h)))

  // Only actual equivocators get slashed (no false positives)
  val slashing_safety_inv =
    slashed.forall(v => has_equivocated(votes, v))

  // At DONE, every equivocator has been detected
  val equivocation_accountability_inv =
    (phase == "DONE") implies
      VALIDATORS.forall(v =>
        has_equivocated(votes, v) implies equivocations_detected.contains(v)
      )

  // Every finalized block (except genesis) had >= THRESHOLD precommits in some round
  val threshold_integrity_inv =
    finalized.forall(b =>
      b == 0 or 1.to(NUM_ROUNDS).exists(r =>
        count_votes_for(b, r, "precommit", votes) >= THRESHOLD
      )
    )

  // Two conflicting blocks can't both have supermajority precommits without equivocation
  val quorum_intersection_inv =
    1.to(NUM_ROUNDS).forall(r =>
      ALL_BLOCKS.forall(b1 =>
        ALL_BLOCKS.forall(b2 =>
          (not(is_ancestor(b1, b2)) and not(is_ancestor(b2, b1))
           and voters_for(b1, r, "precommit", votes).size() >= THRESHOLD
           and voters_for(b2, r, "precommit", votes).size() >= THRESHOLD)
          implies
            voters_for(b1, r, "precommit", votes)
              .intersect(voters_for(b2, r, "precommit", votes)).size() > 0
        )
      )
    )
}
