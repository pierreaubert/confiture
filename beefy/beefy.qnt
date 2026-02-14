//                                                                          -*- quint -*-

module beefy {
  // --- TYPES & CONSTANTS ---
  type Validator = str
  type Payload = str
  type Commitment = { block_num: int, payload: Payload }
  type Vote = { commitment: Commitment, signer: Validator }

  // We model a BFT network with 3 Honest Validators and 1 Malicious Validator (N=4).
  pure val HONEST: Set[Validator] = Set("H1", "H2", "H3")
  pure val MALICIOUS: Set[Validator] = Set("M1")
  pure val VALIDATORS: Set[Validator] = HONEST.union(MALICIOUS)

  // Supermajority threshold: > 2/3 of the validator set.
  // For N=4, 2/3 is 2.66. Thus, a valid BEEFY commitment strictly requires 3 signatures.
  pure val THRESHOLD: int = 3

  // Number of rounds (one per finalized block)
  pure val NUM_ROUNDS: int = 3

  // The valid MMR root for each block number
  pure val VALID_PAYLOAD: int -> Payload = Map(1 -> "MMR_1", 2 -> "MMR_2", 3 -> "MMR_3")

  // A forged MMR root that malicious validators may sign
  pure val FAKE_PAYLOAD: Payload = "FAKE_MMR"

  // --- STATE VARIABLES ---
  var phase: str                                // "VOTE", "RELAY", "SLASH", "DONE"
  var current_round: int                        // which block is being voted on (1..NUM_ROUNDS)
  var votes: Set[Vote]                          // all votes cast across all rounds (persists)
  var bridge_accepted: int -> Payload           // block_num -> accepted payload on bridge
  var equivocations_detected: Set[Validator]    // validators caught equivocating
  var slashed: Set[Validator]                   // validators removed from active set
  var online: Set[Validator]                    // validators currently online

  // --- HELPER FUNCTIONS ---

  // Safe accessor for VALID_PAYLOAD (avoids key error when current_round > NUM_ROUNDS)
  pure def valid_payload_for(round: int): Payload =
    if (VALID_PAYLOAD.keys().contains(round)) VALID_PAYLOAD.get(round)
    else "NONE"

  // Get the set of validators who signed a specific commitment
  pure def signers_for(vs: Set[Vote], block: int, p: Payload): Set[Validator] =
    vs.filter(v => v.commitment.block_num == block and v.commitment.payload == p)
      .map(v => v.signer)

  // Check if a validator signed two different payloads for any block
  pure def has_equivocated(vs: Set[Vote], v: Validator): bool =
    vs.exists(v1 =>
      vs.exists(v2 =>
        v1.signer == v and v2.signer == v
        and v1.commitment.block_num == v2.commitment.block_num
        and v1.commitment.payload != v2.commitment.payload
      )
    )

  // --- INITIALIZATION ---
  action init = all {
    phase' = "VOTE",
    current_round' = 1,
    votes' = Set(),
    bridge_accepted' = Map(),
    equivocations_detected' = Set(),
    slashed' = Set(),
    online' = VALIDATORS,
  }

  // --- ACTIONS (STATE TRANSITIONS) ---

  // Phase A — Honest validators sign the valid payload for the current round
  action cast_honest_vote = {
    nondet h = HONEST.oneOf()
    all {
      phase == "VOTE",
      online.contains(h),
      not(slashed.contains(h)),
      votes' = votes.union(Set({
        commitment: { block_num: current_round, payload: valid_payload_for(current_round) },
        signer: h,
      })),
      phase' = phase,
      current_round' = current_round,
      bridge_accepted' = bridge_accepted,
      equivocations_detected' = equivocations_detected,
      slashed' = slashed,
      online' = online,
    }
  }

  // Phase A — Malicious validators sign a nondeterministically chosen payload (valid or fake)
  // Can be called multiple times with different payloads to model equivocation
  action cast_malicious_vote = {
    nondet m = MALICIOUS.oneOf()
    nondet p = Set(valid_payload_for(current_round), FAKE_PAYLOAD).oneOf()
    all {
      phase == "VOTE",
      online.contains(m),
      not(slashed.contains(m)),
      votes' = votes.union(Set({
        commitment: { block_num: current_round, payload: p },
        signer: m,
      })),
      phase' = phase,
      current_round' = current_round,
      bridge_accepted' = bridge_accepted,
      equivocations_detected' = equivocations_detected,
      slashed' = slashed,
      online' = online,
    }
  }

  // Phase B — End voting: nondeterministic transition modeling the relayer deciding to relay
  action end_voting = all {
    phase == "VOTE",
    phase' = "RELAY",
    current_round' = current_round,
    votes' = votes,
    bridge_accepted' = bridge_accepted,
    equivocations_detected' = equivocations_detected,
    slashed' = slashed,
    online' = online,
  }

  // Phase C — Relayer picks a payload; if >= THRESHOLD unique signers, bridge accepts it
  action relay_commitment = {
    nondet p = Set(valid_payload_for(current_round), FAKE_PAYLOAD).oneOf()
    val signers = signers_for(votes, current_round, p)
    all {
      phase == "RELAY",
      signers.size() >= THRESHOLD,
      not(bridge_accepted.keys().contains(current_round)),
      bridge_accepted' = bridge_accepted.put(current_round, p),
      phase' = "SLASH",
      current_round' = current_round,
      votes' = votes,
      equivocations_detected' = equivocations_detected,
      slashed' = slashed,
      online' = online,
    }
  }

  // Phase C — No payload has supermajority, skip to equivocation detection
  action skip_relay = all {
    phase == "RELAY",
    // No payload reaches threshold for the current round
    Set(valid_payload_for(current_round), FAKE_PAYLOAD).forall(p =>
      signers_for(votes, current_round, p).size() < THRESHOLD
    ),
    phase' = "SLASH",
    current_round' = current_round,
    votes' = votes,
    bridge_accepted' = bridge_accepted,
    equivocations_detected' = equivocations_detected,
    slashed' = slashed,
    online' = online,
  }

  // Phase D — Detect equivocators, slash them, advance round
  action slash_and_advance = {
    // Detect ALL equivocators across all rounds
    val new_equivocators = VALIDATORS.filter(v => has_equivocated(votes, v))
    // Nondeterministically choose online set for the next round
    nondet next_online = VALIDATORS.powerset().oneOf()
    all {
      phase == "SLASH",
      equivocations_detected' = new_equivocators,
      slashed' = slashed.union(new_equivocators),
      online' = next_online,
      current_round' = current_round + 1,
      phase' = if (current_round >= NUM_ROUNDS) "DONE" else "VOTE",
      votes' = votes,
      bridge_accepted' = bridge_accepted,
    }
  }

  // Idle (stuttering step) — prevents deadlock after all rounds complete
  action idle = all {
    phase == "DONE",
    phase' = phase,
    current_round' = current_round,
    votes' = votes,
    bridge_accepted' = bridge_accepted,
    equivocations_detected' = equivocations_detected,
    slashed' = slashed,
    online' = online,
  }

  // --- STATE TRANSITIONS ---
  action step = any {
    cast_honest_vote,
    cast_malicious_vote,
    end_voting,
    relay_commitment,
    skip_relay,
    slash_and_advance,
    idle,
  }

  // ==========================================
  // --- INVARIANTS (CORRECTNESS PROPERTIES) ---
  // ==========================================

  // Safety: Fake payload never accepted by bridge
  val bridge_safety_inv =
    bridge_accepted.keys().forall(b => bridge_accepted.get(b) != FAKE_PAYLOAD)

  // Valid finality: Every accepted payload matches the expected valid payload for that block
  val valid_finality_inv =
    bridge_accepted.keys().forall(b => bridge_accepted.get(b) == VALID_PAYLOAD.get(b))

  // Honest validators never sign conflicting commitments for the same block
  val honest_no_equivocation_inv =
    HONEST.forall(h => not(has_equivocated(votes, h)))

  // Slashing safety: Only actual equivocators get slashed (no false positives)
  val slashing_safety_inv =
    slashed.forall(v => has_equivocated(votes, v))

  // Equivocation accountability: By the end of the protocol, every equivocator has been detected.
  // (Slashed validators cannot cast new votes, so no equivocations go undetected.)
  val equivocation_accountability_inv =
    (phase == "DONE") implies
      VALIDATORS.forall(v =>
        has_equivocated(votes, v) implies equivocations_detected.contains(v)
      )

  // Threshold integrity: Every accepted payload had >= THRESHOLD unique signers
  val threshold_integrity_inv =
    bridge_accepted.keys().forall(b =>
      signers_for(votes, b, bridge_accepted.get(b)).size() >= THRESHOLD
    )

  // Quorum intersection: If two different payloads both have supermajority for the same block,
  // some validator must have signed both (equivocation proof exists)
  val quorum_intersection_inv =
    1.to(NUM_ROUNDS).forall(b =>
      Set(VALID_PAYLOAD.get(b), FAKE_PAYLOAD).forall(p1 =>
        Set(VALID_PAYLOAD.get(b), FAKE_PAYLOAD).forall(p2 =>
          (p1 != p2 and signers_for(votes, b, p1).size() >= THRESHOLD
                    and signers_for(votes, b, p2).size() >= THRESHOLD)
          implies
            signers_for(votes, b, p1).intersect(signers_for(votes, b, p2)).size() > 0
        )
      )
    )
}
