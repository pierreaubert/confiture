//                                                                          -*- quint -*-

module grandpa_v3 {
  // --- TYPES & CONSTANTS ---
  type Validator = int
  type Block = { hash: int, parent: int, height: int }
  type VoteKind = Prevote | Precommit
  type Vote = { voter: Validator, round: int, block_hash: int, kind: VoteKind }
  type Justification = { block_hash: int, round: int, signatures: Set[Validator] }

  type Phase = PrevotePhase | PrecommitPhase | FinalizePhase

  type ValidatorState = {
    round: int,
    phase: Phase,
    last_finalized: int
  }

  // Parameters for benchmarking and scaling
  pure val N: int = 4
  pure val F: int = 1
  pure val VALIDATORS: Set[Validator] = 1.to(N)
  pure val HONEST: Set[Validator] = 1.to(N - F)
  pure val MALICIOUS: Set[Validator] = (N - F + 1).to(N)
  pure val THRESHOLD: int = 2 * N / 3 + 1 // Supermajority

  pure val MAX_ROUND: int = 3
  pure val MAX_HEIGHT: int = 4

  // --- STATE VARIABLES ---
  var blocks: int -> Block                    // The block tree
  var next_hash: int                          // Next hash to assign
  var local_states: Validator -> ValidatorState
  var network: Set[Vote]                      // All broadcasted messages
  var justifications: Set[Justification]      // Broadcasted justifications
  var connected: Validator -> Set[Validator]  // Network topology (who can see whom)
  var global_finalized: Set[int]              // For property checking
  var slashed: Set[Validator]

  // --- HELPER FUNCTIONS ---

  pure def is_ancestor(target: int, block: int, tree: int -> Block): bool = {
    val steps = 0.to(MAX_HEIGHT)
    val final_pos = steps.fold(block, (curr, _step) =>
      if (curr == target) curr 
      else if (tree.keys().contains(curr)) tree.get(curr).parent
      else curr
    )
    final_pos == target
  }

  // Filter network view based on connectivity
  pure def view(v: Validator, net: Set[Vote], conn: Validator -> Set[Validator]): Set[Vote] =
    net.filter(msg => conn.get(v).contains(msg.voter))

  pure def voters_for(target: int, r: int, k: VoteKind, votes: Set[Vote], tree: int -> Block): Set[Validator] =
    votes.filter(v => v.kind == k and v.round == r and is_ancestor(target, v.block_hash, tree))
      .map(v => v.voter)

  pure def count_votes_for(target: int, r: int, k: VoteKind, votes: Set[Vote], tree: int -> Block): int =
    voters_for(target, r, k, votes, tree).size()

  pure def ghost_candidate(r: int, votes: Set[Vote], tree: int -> Block): int =
    tree.keys().fold(0, (best, b) =>
      if (count_votes_for(b, r, Prevote, votes, tree) >= THRESHOLD
          and tree.get(b).height > tree.get(best).height) b
      else best
    )

  pure def has_equivocated(votes: Set[Vote], v: Validator): bool =
    votes.exists(v1 =>
      votes.exists(v2 =>
        v1.voter == v and v2.voter == v
        and v1.round == v2.round
        and v1.kind == v2.kind
        and v1.block_hash != v2.block_hash
      )
    )

  pure def ancestors_of(b: int, tree: int -> Block): Set[int] = {
    val steps = 0.to(MAX_HEIGHT)
    steps.fold(Set(b), (acc, _step) =>
      acc.union(acc.map(curr => if (tree.keys().contains(curr)) tree.get(curr).parent else curr))
    )
  }

  // --- INITIALIZATION ---
  action init = all {
    blocks' = Map(0 -> { hash: 0, parent: 0, height: 0 }),
    next_hash' = 1,
    local_states' = VALIDATORS.mapBy(_ => { round: 1, phase: PrevotePhase, last_finalized: 0 }),
    network' = Set(),
    justifications' = Set(),
    // Initially fully connected
    connected' = VALIDATORS.mapBy(_ => VALIDATORS),
    global_finalized' = Set(0),
    slashed' = Set(),
  }

  // --- ACTIONS ---

  // Network: Create a partition
  // Splits validators into two groups: A and B. A can't see B, B can't see A.
  action partition_network = {
    nondet pivot = 1.to(N - 1).oneOf()
    val groupA = 1.to(N).filter(i => i <= pivot)
    val groupB = 1.to(N).filter(i => i > pivot)
    all {
      // Only partitioning if currently fully connected (simplification)
      connected.get(1) == VALIDATORS,
      connected' = VALIDATORS.mapBy(v => if (groupA.contains(v)) groupA else groupB),
      blocks' = blocks, next_hash' = next_hash, local_states' = local_states,
      network' = network, justifications' = justifications, global_finalized' = global_finalized, slashed' = slashed
    }
  }

  // Network: Heal partition
  action heal_network = all {
    connected != VALIDATORS.mapBy(_ => VALIDATORS),
    connected' = VALIDATORS.mapBy(_ => VALIDATORS),
    blocks' = blocks, next_hash' = next_hash, local_states' = local_states,
    network' = network, justifications' = justifications, global_finalized' = global_finalized, slashed' = slashed
  }

  // 1. Dynamic Block Production
  action produce_block = {
    nondet parent = blocks.keys().oneOf()
    all {
      next_hash < MAX_HEIGHT,
      blocks' = blocks.put(next_hash, { hash: next_hash, parent: parent, height: blocks.get(parent).height + 1 }),
      next_hash' = next_hash + 1,
      local_states' = local_states, network' = network, justifications' = justifications,
      global_finalized' = global_finalized, slashed' = slashed, connected' = connected
    }
  }

  // 2. Honest Prevote
  action honest_prevote(v: Validator): bool = {
    val state = local_states.get(v)
    val my_view = view(v, network, connected)
    // Vote for the best block known that extends the last finalized block
    // Using GHOST on *my view* would be more realistic, but for Prevote usually we just extend the head
    // Simplified: pick any block that is an ancestor of a leaf and extends last_finalized
    nondet b = blocks.keys().oneOf()
    all {
      HONEST.contains(v),
      state.phase == PrevotePhase,
      not(slashed.contains(v)),
      is_ancestor(state.last_finalized, b, blocks),
      network' = network.union(Set({ voter: v, round: state.round, block_hash: b, kind: Prevote })),
      local_states' = local_states.set(v, { ...state, phase: PrecommitPhase }),
      blocks' = blocks, next_hash' = next_hash, justifications' = justifications,
      global_finalized' = global_finalized, slashed' = slashed, connected' = connected
    }
  }

  // 3. Honest Precommit
  action honest_precommit(v: Validator): bool = {
    val state = local_states.get(v)
    val my_view = view(v, network, connected)
    val candidate = ghost_candidate(state.round, my_view, blocks)
    all {
      HONEST.contains(v),
      state.phase == PrecommitPhase,
      not(slashed.contains(v)),
      network' = network.union(Set({ voter: v, round: state.round, block_hash: candidate, kind: Precommit })),
      local_states' = local_states.set(v, { ...state, phase: FinalizePhase }),
      blocks' = blocks, next_hash' = next_hash, justifications' = justifications,
      global_finalized' = global_finalized, slashed' = slashed, connected' = connected
    }
  }

  // 4. Honest Finalize & Advance Round (using Justifications)
  action honest_finalize_and_advance(v: Validator): bool = {
    val state = local_states.get(v)
    val my_view = view(v, network, connected)
    
    // Check if we can form a justification from our view
    val finalized_candidates = blocks.keys().filter(b => 
      count_votes_for(b, state.round, Precommit, my_view, blocks) >= THRESHOLD
    )
    
    all {
      finalized_candidates.size() > 0,
      // Pick best finalized
       val best_finalized = finalized_candidates.fold(state.last_finalized, (best, b) =>
        if (blocks.get(b).height > blocks.get(best).height) b else best
      )
      // Construct justification
      val signers = voters_for(best_finalized, state.round, Precommit, my_view, blocks)
      val new_justification = { block_hash: best_finalized, round: state.round, signatures: signers }
      
      all {
        HONEST.contains(v),
        state.phase == FinalizePhase,
        state.round < MAX_ROUND,
        local_states' = local_states.set(v, { round: state.round + 1, phase: PrevotePhase, last_finalized: best_finalized }),
        global_finalized' = global_finalized.union(ancestors_of(best_finalized, blocks)),
        justifications' = justifications.union(Set(new_justification)),
        blocks' = blocks, next_hash' = next_hash, network' = network,
        slashed' = slashed, connected' = connected
      }
    }
  }

  // 5. Malicious Behavior
  action malicious_equivocate(v: Validator): bool = {
    val state = local_states.get(v)
    nondet b1 = blocks.keys().oneOf()
    nondet b2 = blocks.keys().oneOf()
    nondet k = Set(Prevote, Precommit).oneOf()
    all {
      MALICIOUS.contains(v),
      b1 != b2,
      not(slashed.contains(v)),
      network' = network.union(Set(
        { voter: v, round: state.round, block_hash: b1, kind: k },
        { voter: v, round: state.round, block_hash: b2, kind: k }
      )),
      blocks' = blocks, next_hash' = next_hash, local_states' = local_states,
      justifications' = justifications, global_finalized' = global_finalized,
      slashed' = slashed, connected' = connected
    }
  }

  // 6. Detection and Slashing (Global view for simplicity of the model)
  action detect_and_slash = {
    val newly_detected = VALIDATORS.filter(v => has_equivocated(network, v))
    all {
      newly_detected.size() > 0,
      slashed' = slashed.union(newly_detected),
      blocks' = blocks, next_hash' = next_hash, local_states' = local_states,
      network' = network, justifications' = justifications, global_finalized' = global_finalized,
      connected' = connected
    }
  }

  action step = any {
    produce_block,
    partition_network,
    heal_network,
    nondet v = VALIDATORS.oneOf()
    any {
      honest_prevote(v),
      honest_precommit(v),
      honest_finalize_and_advance(v),
      malicious_equivocate(v)
    },
    detect_and_slash
  }

  // --- INVARIANTS ---

  val safety = global_finalized.forall(b1 =>
    global_finalized.forall(b2 =>
      (blocks.get(b1).height == blocks.get(b2).height) implies (b1 == b2)
    )
  )

  // Accountable Safety
  val accountable_safety = 
    not(safety) implies (VALIDATORS.filter(v => has_equivocated(network, v)).size() >= 2) // >= f+1

  // Liveness check: we want to ensure we don't get stuck forever
  // (Requires heal_network if partitioned)
  
  // Consistency of Justifications
  val valid_justifications = justifications.forall(j =>
    j.signatures.size() >= THRESHOLD and
    // In a real check we would verify the signatures match the block, modeled here by construction
    true
  )
}
