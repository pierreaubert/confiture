//                                                                          -*- quint -*-

module beefy_v2 {
  // --- TYPES & CONSTANTS ---
  type Validator = str
  type Payload = str
  type Commitment = { block_num: int, payload: Payload }
  type Vote = { commitment: Commitment, signer: Validator }

  // BEEFY targets finalized blocks.
  // We model a source chain that produces finalized blocks.
  type SourceChain = {
    finalized_height: int,
    payloads: int -> Payload
  }

  // The bridge exists on the target chain.
  type Bridge = {
    best_finalized_height: int,
    accepted_payloads: int -> Payload
  }

  pure val VALIDATORS: Set[Validator] = Set("H1", "H2", "H3", "M1")
  pure val HONEST: Set[Validator] = Set("H1", "H2", "H3")
  pure val MALICIOUS: Set[Validator] = Set("M1")
  pure val THRESHOLD: int = 3 // 2f+1 for N=4

  pure val MAX_HEIGHT: int = 4

  // --- STATE VARIABLES ---
  var source_chain: SourceChain
  var bridge: Bridge
  var votes: Set[Vote]                        // Message pool (signatures)
  var validator_heights: Validator -> int     // Local view of each validator
  var slashed: Set[Validator]

  // --- HELPER FUNCTIONS ---

  // Check if a validator signed two different payloads for the same block
  pure def has_equivocated(vs: Set[Vote], v: Validator): bool =
    vs.exists(v1 =>
      vs.exists(v2 =>
        v1.signer == v and v2.signer == v
        and v1.commitment.block_num == v2.commitment.block_num
        and v1.commitment.payload != v2.commitment.payload
      )
    )

  // Get signers for a specific commitment
  pure def signers_for(vs: Set[Vote], block: int, p: Payload): Set[Validator] =
    vs.filter(v => v.commitment.block_num == block and v.commitment.payload == p)
      .map(v => v.signer)

  // --- INITIALIZATION ---
  action init = all {
    source_chain' = { 
      finalized_height: 0, 
      payloads: Map(0 -> "GENESIS") 
    },
    bridge' = { 
      best_finalized_height: 0, 
      accepted_payloads: Map(0 -> "GENESIS") 
    },
    votes' = Set(),
    validator_heights' = VALIDATORS.mapBy(_ => 0),
    slashed' = Set(),
  }

  // --- ACTIONS ---

  // 1. Source Chain Finalizes a New Block
  action source_finalize_block = {
    val next_h = source_chain.finalized_height + 1
    all {
      next_h <= MAX_HEIGHT,
      source_chain' = {
        finalized_height: next_h,
        payloads: source_chain.payloads.put(next_h, "MMR_".concat(valToString(next_h)))
      },
      bridge' = bridge,
      votes' = votes,
      validator_heights' = validator_heights,
      slashed' = slashed,
    }
  }

  // 2. Honest Validator Signs a Commitment
  action honest_sign(v: Validator) = {
    val current_h = validator_heights.get(v)
    val next_h = current_h + 1
    all {
      HONEST.contains(v),
      not(slashed.contains(v)),
      // Validator only signs if source chain has finalized a new block
      source_chain.finalized_height >= next_h,
      // In BEEFY, validators sign the mandatory block (simplified: every block)
      votes' = votes.union(Set({
        commitment: { block_num: next_h, payload: source_chain.payloads.get(next_h) },
        signer: v
      })),
      validator_heights' = validator_heights.set(v, next_h),
      source_chain' = source_chain,
      bridge' = bridge,
      slashed' = slashed,
    }
  }

  // 3. Malicious Validator Equivocates
  action malicious_equivocate(v: Validator) = {
    nondet h = 1.to(MAX_HEIGHT).oneOf()
    nondet p1 = "FAKE_1"
    nondet p2 = "FAKE_2"
    all {
      MALICIOUS.contains(v),
      not(slashed.contains(v)),
      votes' = votes.union(Set(
        { commitment: { block_num: h, payload: p1 }, signer: v },
        { commitment: { block_num: h, payload: p2 }, signer: v }
      )),
      source_chain' = source_chain,
      bridge' = bridge,
      validator_heights' = validator_heights,
      slashed' = slashed,
    }
  }

  // 4. Relayer Submits Proof to Bridge
  action relay_to_bridge = {
    // Relayer picks a block and a payload that has enough signatures
    nondet h = 1.to(MAX_HEIGHT).oneOf()
    nondet p = votes.map(v => v.commitment.payload).oneOf()
    val signers = signers_for(votes, h, p)
    all {
      signers.size() >= THRESHOLD,
      // Bridge only accepts blocks in order (simplified BEEFY)
      h == bridge.best_finalized_height + 1,
      bridge' = {
        best_finalized_height: h,
        accepted_payloads: bridge.accepted_payloads.put(h, p)
      },
      source_chain' = source_chain,
      votes' = votes,
      validator_heights' = validator_heights,
      slashed' = slashed,
    }
  }

  // 5. Slashing Detection
  action detect_and_slash = {
    val newly_detected = VALIDATORS.filter(v => has_equivocated(votes, v))
    all {
      newly_detected.size() > 0,
      slashed' = slashed.union(newly_detected),
      source_chain' = source_chain,
      bridge' = bridge,
      votes' = votes,
      validator_heights' = validator_heights,
    }
  }

  action step = any {
    source_finalize_block,
    nondet v = VALIDATORS.oneOf()
    any {
      honest_sign(v),
      malicious_equivocate(v)
    },
    relay_to_bridge,
    detect_and_slash
  }

  // --- INVARIANTS ---

  // Safety: Bridge never accepts a payload that doesn't match the source chain
  val bridge_safety = bridge.accepted_payloads.keys().forall(h =>
    bridge.accepted_payloads.get(h) == source_chain.payloads.get(h)
  )

  // Accountable Safety: If bridge_safety is violated, at least f+1 validators must have equivocated
  // (In BEEFY, if an invalid payload is accepted, it must have >= THRESHOLD signatures)
  val accountable_safety =
    (exists h in bridge.accepted_payloads.keys(): 
      bridge.accepted_payloads.get(h) != source_chain.payloads.get(h))
    implies (VALIDATORS.filter(v => has_equivocated(votes, v)).size() >= 2)

  // Honest signatures are always valid
  val honest_integrity = votes.forall(v =>
    HONEST.contains(v.signer) implies (v.commitment.payload == source_chain.payloads.get(v.commitment.block_num))
  )

  // --- TEMPORAL PROPERTIES ---

  // Liveness: Bridge eventually catches up to source chain's finalized height
  temporal val liveness = eventually(bridge.best_finalized_height == source_chain.finalized_height)

}
