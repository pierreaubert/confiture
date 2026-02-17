//                                                                          -*- quint -*-

module grandpa_v3 {
  // --- TYPES & CONSTANTS ---
  type Validator = int
  type Block = { hash: int, parent: int, height: int }
  type VoteKind = Prevote | Precommit
  type Vote = { voter: Validator, round: int, block_hash: int, kind: VoteKind }
  type Justification = { block_hash: int, round: int, signatures: Set[Validator] }

  type Phase = WaitingForPrimary | PrevotePhase | PrecommitPhase | FinalizePhase

  type ValidatorState = {
    round: int,
    phase: Phase,
    last_finalized: int,
    prevote_ghost: int,
    estimate: int,
    received_primary_estimate: int,
    completable: bool,
    round_start_time: int
  }

  type CommitMessage = { block_hash: int, round: int, precommits: Set[Vote] }
  type PrimaryMessage = { proposer: Validator, round: int, estimate: int }
  type CatchUpRequest = { from: Validator, to: Validator, round: int }
  type CatchUpResponse = { round: int, prevotes: Set[Vote], precommits: Set[Vote], last_finalized: int }

  // NIL_VOTE for nil precommits (no block to commit)
  pure val NIL_VOTE: int = -1
  // Sentinel: no primary estimate received yet
  pure val NO_ESTIMATE: int = -2

  // Parameters for benchmarking and scaling
  pure val N: int = 4
  pure val F: int = 1
  pure val VALIDATORS: Set[Validator] = 1.to(N)
  pure val HONEST: Set[Validator] = 1.to(N - F)
  pure val MALICIOUS: Set[Validator] = (N - F + 1).to(N)
  pure val THRESHOLD: int = 2 * N / 3 + 1 // Supermajority

  pure val MAX_ROUND: int = 3
  pure val MAX_HEIGHT: int = 4
  pure val MAX_CLOCK: int = 10
  pure val TIMER_THRESHOLD: int = 2 // time units before timeout

  // --- STATE VARIABLES ---
  var blocks: int -> Block                    // The block tree
  var next_hash: int                          // Next hash to assign
  var local_states: Validator -> ValidatorState
  var network: Set[Vote]                      // All broadcasted votes
  var justifications: Set[Justification]      // Broadcasted justifications
  var connected: Validator -> Set[Validator]   // Network topology
  var global_finalized: Set[int]              // For property checking
  var slashed: Set[Validator]
  var logical_clock: int                      // Abstract time for timer modeling
  var commit_messages: Set[CommitMessage]
  var primary_messages: Set[PrimaryMessage]
  var catchup_requests: Set[CatchUpRequest]
  var catchup_responses: Set[CatchUpResponse]

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

  pure def ancestors_of(b: int, tree: int -> Block): Set[int] = {
    val steps = 0.to(MAX_HEIGHT)
    steps.fold(Set(b), (acc, _step) =>
      acc.union(acc.map(curr => if (tree.keys().contains(curr)) tree.get(curr).parent else curr))
    )
  }

  // Direct children of a node in the tree
  pure def children_of(node: int, tree: int -> Block): Set[int] =
    tree.keys().filter(b => tree.get(b).parent == node and b != node)

  // Filter network view based on connectivity
  pure def view(v: Validator, net: Set[Vote], conn: Validator -> Set[Validator]): Set[Vote] =
    net.filter(msg => conn.get(v).contains(msg.voter))

  // Round-robin primary selection
  pure def primary(r: int): Validator = (r - 1) % N + 1

  // --- TOLERANT VOTE COUNTING (equivocation-aware) ---

  // Equivocators: validators who cast conflicting votes in round r for kind k
  pure def equivocators(r: int, k: VoteKind, votes: Set[Vote]): Set[Validator] =
    VALIDATORS.filter(v =>
      votes.exists(v1 =>
        votes.exists(v2 =>
          v1.voter == v and v2.voter == v
          and v1.round == r and v2.round == r
          and v1.kind == k and v2.kind == k
          and v1.block_hash != v2.block_hash
        )
      )
    )

  // Direct voters for target (votes for target or any of its descendants)
  pure def direct_voters_for(target: int, r: int, k: VoteKind, votes: Set[Vote], tree: int -> Block): Set[Validator] =
    votes.filter(v => v.kind == k and v.round == r and is_ancestor(target, v.block_hash, tree))
      .map(v => v.voter)

  // Tolerant voters: direct voters PLUS all equivocators (pessimistic counting per GRANDPA paper)
  pure def tolerant_voters_for(target: int, r: int, k: VoteKind, votes: Set[Vote], tree: int -> Block): Set[Validator] =
    direct_voters_for(target, r, k, votes, tree).union(equivocators(r, k, votes))

  pure def tolerant_count(target: int, r: int, k: VoteKind, votes: Set[Vote], tree: int -> Block): int =
    tolerant_voters_for(target, r, k, votes, tree).size()

  // --- PROPER GHOST (tree-walking) ---
  // Start from last_finalized, at each fork pick child with >= THRESHOLD tolerant prevotes,
  // descend until no child qualifies. Bounded by MAX_HEIGHT fold iterations.
  pure def ghost(r: int, votes: Set[Vote], tree: int -> Block, start: int): int = {
    val steps = 0.to(MAX_HEIGHT)
    steps.fold(start, (curr, _step) => {
      val qualifying = children_of(curr, tree).filter(c =>
        tolerant_count(c, r, Prevote, votes, tree) >= THRESHOLD
      )
      if (qualifying.size() == 0) curr
      else
        // Pick child with highest tolerant prevote count, break ties by higher hash
        qualifying.fold(curr, (best, c) =>
          if (best == curr) c
          else if (tolerant_count(c, r, Prevote, votes, tree) > tolerant_count(best, r, Prevote, votes, tree)) c
          else if (tolerant_count(c, r, Prevote, votes, tree) == tolerant_count(best, r, Prevote, votes, tree) and c > best) c
          else best
        )
    })
  }

  // Has equivocated (for detection/slashing)
  pure def has_equivocated(votes: Set[Vote], v: Validator): bool =
    votes.exists(v1 =>
      votes.exists(v2 =>
        v1.voter == v and v2.voter == v
        and v1.round == v2.round
        and v1.kind == v2.kind
        and v1.block_hash != v2.block_hash
      )
    )

  // --- COMPLETABILITY ---
  // A round is completable when the prevote GHOST g is determined and no block
  // off the GHOST chain can reach threshold with the remaining uncast precommits.
  pure def is_completable(r: int, votes: Set[Vote], tree: int -> Block, last_fin: int): bool = {
    val g = ghost(r, votes, tree, last_fin)
    val voted = votes.filter(v => v.kind == Precommit and v.round == r).map(v => v.voter)
    val remaining = N - voted.size()
    // Every block NOT on the GHOST chain (not a descendant-or-equal of g)
    // cannot reach threshold even if all remaining voters precommit for it.
    tree.keys().forall(b =>
      is_ancestor(g, b, tree)
      or (tolerant_count(b, r, Precommit, votes, tree) + remaining < THRESHOLD)
    )
  }

  // --- INITIALIZATION ---
  action init = all {
    blocks' = Map(0 -> { hash: 0, parent: 0, height: 0 }),
    next_hash' = 1,
    local_states' = VALIDATORS.mapBy(_ => {
      round: 1,
      phase: WaitingForPrimary,
      last_finalized: 0,
      prevote_ghost: 0,
      estimate: 0,
      received_primary_estimate: NO_ESTIMATE,
      completable: false,
      round_start_time: 0
    }),
    network' = Set(),
    justifications' = Set(),
    connected' = VALIDATORS.mapBy(_ => VALIDATORS),
    global_finalized' = Set(0),
    slashed' = Set(),
    logical_clock' = 0,
    commit_messages' = Set(),
    primary_messages' = Set(),
    catchup_requests' = Set(),
    catchup_responses' = Set(),
  }

  // --- ACTIONS ---

  // Advance abstract logical clock (bounded)
  action tick_clock = all {
    logical_clock < MAX_CLOCK,
    logical_clock' = logical_clock + 1,
    blocks' = blocks, next_hash' = next_hash, local_states' = local_states,
    network' = network, justifications' = justifications, connected' = connected,
    global_finalized' = global_finalized, slashed' = slashed,
    commit_messages' = commit_messages, primary_messages' = primary_messages,
    catchup_requests' = catchup_requests, catchup_responses' = catchup_responses,
  }

  // Network: Create a partition
  action partition_network = {
    nondet pivot = 1.to(N - 1).oneOf()
    val groupA = 1.to(N).filter(i => i <= pivot)
    val groupB = 1.to(N).filter(i => i > pivot)
    all {
      connected.get(1) == VALIDATORS,
      connected' = VALIDATORS.mapBy(v => if (groupA.contains(v)) groupA else groupB),
      blocks' = blocks, next_hash' = next_hash, local_states' = local_states,
      network' = network, justifications' = justifications,
      global_finalized' = global_finalized, slashed' = slashed,
      logical_clock' = logical_clock, commit_messages' = commit_messages,
      primary_messages' = primary_messages, catchup_requests' = catchup_requests,
      catchup_responses' = catchup_responses,
    }
  }

  // Network: Heal partition
  action heal_network = all {
    connected != VALIDATORS.mapBy(_ => VALIDATORS),
    connected' = VALIDATORS.mapBy(_ => VALIDATORS),
    blocks' = blocks, next_hash' = next_hash, local_states' = local_states,
    network' = network, justifications' = justifications,
    global_finalized' = global_finalized, slashed' = slashed,
    logical_clock' = logical_clock, commit_messages' = commit_messages,
    primary_messages' = primary_messages, catchup_requests' = catchup_requests,
    catchup_responses' = catchup_responses,
  }

  // Dynamic Block Production
  action produce_block = {
    nondet parent = blocks.keys().oneOf()
    all {
      next_hash < MAX_HEIGHT,
      blocks' = blocks.put(next_hash, { hash: next_hash, parent: parent, height: blocks.get(parent).height + 1 }),
      next_hash' = next_hash + 1,
      local_states' = local_states, network' = network, justifications' = justifications,
      global_finalized' = global_finalized, slashed' = slashed, connected' = connected,
      logical_clock' = logical_clock, commit_messages' = commit_messages,
      primary_messages' = primary_messages, catchup_requests' = catchup_requests,
      catchup_responses' = catchup_responses,
    }
  }

  // --- PRIMARY PROPOSER ---

  // Primary broadcasts estimate (GHOST from previous round, or last_finalized for round 1)
  action primary_broadcast(v: Validator): bool = {
    val state = local_states.get(v)
    val my_view = view(v, network, connected)
    val est = if (state.round == 1) state.last_finalized
              else ghost(state.round - 1, my_view, blocks, state.last_finalized)
    all {
      HONEST.contains(v),
      not(slashed.contains(v)),
      state.phase == WaitingForPrimary,
      primary(state.round) == v,
      primary_messages' = primary_messages.union(Set({ proposer: v, round: state.round, estimate: est })),
      local_states' = local_states.set(v, { ...state, phase: PrevotePhase, estimate: est }),
      blocks' = blocks, next_hash' = next_hash, network' = network,
      justifications' = justifications, connected' = connected,
      global_finalized' = global_finalized, slashed' = slashed,
      logical_clock' = logical_clock, commit_messages' = commit_messages,
      catchup_requests' = catchup_requests, catchup_responses' = catchup_responses,
    }
  }

  // Non-primary receives primary's estimate and transitions to PrevotePhase
  action receive_primary_estimate(v: Validator): bool = {
    val state = local_states.get(v)
    val visible_primaries = primary_messages.filter(pm =>
      pm.round == state.round and pm.proposer == primary(state.round)
      and connected.get(v).contains(pm.proposer)
    )
    all {
      HONEST.contains(v),
      not(slashed.contains(v)),
      state.phase == WaitingForPrimary,
      primary(state.round) != v,
      visible_primaries.size() > 0,
      nondet pm = visible_primaries.oneOf()
      all {
        local_states' = local_states.set(v, { ...state, phase: PrevotePhase, received_primary_estimate: pm.estimate }),
        blocks' = blocks, next_hash' = next_hash, network' = network,
        justifications' = justifications, connected' = connected,
        global_finalized' = global_finalized, slashed' = slashed,
        logical_clock' = logical_clock, commit_messages' = commit_messages,
        primary_messages' = primary_messages, catchup_requests' = catchup_requests,
        catchup_responses' = catchup_responses,
      }
    }
  }

  // Timeout waiting for primary: move to PrevotePhase without estimate
  action timeout_waiting_for_primary(v: Validator): bool = {
    val state = local_states.get(v)
    all {
      HONEST.contains(v),
      not(slashed.contains(v)),
      state.phase == WaitingForPrimary,
      primary(state.round) != v,
      logical_clock >= state.round_start_time + TIMER_THRESHOLD,
      local_states' = local_states.set(v, { ...state, phase: PrevotePhase }),
      blocks' = blocks, next_hash' = next_hash, network' = network,
      justifications' = justifications, connected' = connected,
      global_finalized' = global_finalized, slashed' = slashed,
      logical_clock' = logical_clock, commit_messages' = commit_messages,
      primary_messages' = primary_messages, catchup_requests' = catchup_requests,
      catchup_responses' = catchup_responses,
    }
  }

  // --- HONEST PREVOTE ---
  // Prevote for best chain extending primary's estimate (if valid), else extending last_finalized
  action honest_prevote(v: Validator): bool = {
    val state = local_states.get(v)
    val pe = state.received_primary_estimate
    // Use primary's estimate as base if it descends from last_finalized
    val base = if (pe != NO_ESTIMATE and blocks.keys().contains(pe)
                   and is_ancestor(state.last_finalized, pe, blocks)) pe
               else state.last_finalized
    nondet b = blocks.keys().oneOf()
    all {
      HONEST.contains(v),
      not(slashed.contains(v)),
      state.phase == PrevotePhase,
      is_ancestor(base, b, blocks),
      network' = network.union(Set({ voter: v, round: state.round, block_hash: b, kind: Prevote })),
      local_states' = local_states.set(v, { ...state, phase: PrecommitPhase }),
      blocks' = blocks, next_hash' = next_hash, justifications' = justifications,
      global_finalized' = global_finalized, slashed' = slashed, connected' = connected,
      logical_clock' = logical_clock, commit_messages' = commit_messages,
      primary_messages' = primary_messages, catchup_requests' = catchup_requests,
      catchup_responses' = catchup_responses,
    }
  }

  // --- HONEST PRECOMMIT ---
  // Wait for >= THRESHOLD prevotes, compute GHOST, precommit if proper descendant of last_finalized, else NIL
  action honest_precommit(v: Validator): bool = {
    val state = local_states.get(v)
    val my_view = view(v, network, connected)
    val g = ghost(state.round, my_view, blocks, state.last_finalized)
    val has_enough_prevotes = tolerant_count(state.last_finalized, state.round, Prevote, my_view, blocks) >= THRESHOLD
    // Precommit to GHOST if it's a proper descendant of last_finalized, else NIL
    val precommit_target = if (g != state.last_finalized and is_ancestor(state.last_finalized, g, blocks)) g
                           else NIL_VOTE
    all {
      HONEST.contains(v),
      not(slashed.contains(v)),
      state.phase == PrecommitPhase,
      has_enough_prevotes,
      network' = network.union(Set({ voter: v, round: state.round, block_hash: precommit_target, kind: Precommit })),
      local_states' = local_states.set(v, { ...state, phase: FinalizePhase, prevote_ghost: g }),
      blocks' = blocks, next_hash' = next_hash, justifications' = justifications,
      global_finalized' = global_finalized, slashed' = slashed, connected' = connected,
      logical_clock' = logical_clock, commit_messages' = commit_messages,
      primary_messages' = primary_messages, catchup_requests' = catchup_requests,
      catchup_responses' = catchup_responses,
    }
  }

  // --- FINALIZE AND ADVANCE ROUND ---
  // Finalize when a block has >= THRESHOLD precommits, broadcast commit message, advance round
  action honest_finalize_and_advance(v: Validator): bool = {
    val state = local_states.get(v)
    val my_view = view(v, network, connected)

    // Find blocks with supermajority precommits (excluding NIL_VOTE)
    val finalized_candidates = blocks.keys().filter(b =>
      b != NIL_VOTE and tolerant_count(b, state.round, Precommit, my_view, blocks) >= THRESHOLD
    )

    all {
      finalized_candidates.size() > 0,
      val best_finalized = finalized_candidates.fold(state.last_finalized, (best, b) =>
        if (blocks.get(b).height > blocks.get(best).height) b else best
      )
      val signers = direct_voters_for(best_finalized, state.round, Precommit, my_view, blocks)
      val precommit_votes = my_view.filter(vote =>
        vote.kind == Precommit and vote.round == state.round
        and is_ancestor(best_finalized, vote.block_hash, blocks)
      )
      val new_justification = { block_hash: best_finalized, round: state.round, signatures: signers }
      val new_commit = { block_hash: best_finalized, round: state.round, precommits: precommit_votes }

      all {
        HONEST.contains(v),
        state.phase == FinalizePhase,
        state.round < MAX_ROUND,
        local_states' = local_states.set(v, {
          round: state.round + 1,
          phase: WaitingForPrimary,
          last_finalized: best_finalized,
          prevote_ghost: 0,
          estimate: 0,
          received_primary_estimate: NO_ESTIMATE,
          completable: false,
          round_start_time: logical_clock
        }),
        global_finalized' = global_finalized.union(ancestors_of(best_finalized, blocks)),
        justifications' = justifications.union(Set(new_justification)),
        commit_messages' = commit_messages.union(Set(new_commit)),
        blocks' = blocks, next_hash' = next_hash, network' = network,
        slashed' = slashed, connected' = connected,
        logical_clock' = logical_clock, primary_messages' = primary_messages,
        catchup_requests' = catchup_requests, catchup_responses' = catchup_responses,
      }
    }
  }

  // --- TIMER-BASED ROUND ADVANCEMENT ---
  // Advance round without finalization when timer expired AND round is completable
  action timer_advance_round(v: Validator): bool = {
    val state = local_states.get(v)
    val my_view = view(v, network, connected)
    all {
      HONEST.contains(v),
      not(slashed.contains(v)),
      state.phase == FinalizePhase,
      state.round < MAX_ROUND,
      // Timer has expired
      logical_clock >= state.round_start_time + TIMER_THRESHOLD,
      // Round is completable
      is_completable(state.round, my_view, blocks, state.last_finalized),
      // No block achieved supermajority precommits (otherwise would finalize instead)
      blocks.keys().forall(b =>
        tolerant_count(b, state.round, Precommit, my_view, blocks) < THRESHOLD
      ),
      local_states' = local_states.set(v, {
        round: state.round + 1,
        phase: WaitingForPrimary,
        last_finalized: state.last_finalized,
        prevote_ghost: 0,
        estimate: 0,
        received_primary_estimate: NO_ESTIMATE,
        completable: false,
        round_start_time: logical_clock
      }),
      blocks' = blocks, next_hash' = next_hash, network' = network,
      justifications' = justifications, connected' = connected,
      global_finalized' = global_finalized, slashed' = slashed,
      logical_clock' = logical_clock, commit_messages' = commit_messages,
      primary_messages' = primary_messages, catchup_requests' = catchup_requests,
      catchup_responses' = catchup_responses,
    }
  }

  // --- FINALIZE FROM COMMIT MESSAGE ---
  // A validator observes a valid commit message from a peer and updates finalization
  action finalize_from_commit(v: Validator): bool = {
    val state = local_states.get(v)
    all {
      commit_messages.size() > 0,
      nondet cm = commit_messages.oneOf()
      val commit_voters = cm.precommits.filter(vote =>
        is_ancestor(cm.block_hash, vote.block_hash, blocks)
      ).map(vote => vote.voter)
      // Commit is reachable if v is connected to at least one precommit voter
      val reachable = cm.precommits.exists(vote => connected.get(v).contains(vote.voter))
      all {
        HONEST.contains(v),
        not(slashed.contains(v)),
        reachable,
        commit_voters.size() >= THRESHOLD,
        blocks.keys().contains(cm.block_hash),
        // Only apply if it would advance our finalization
        blocks.get(cm.block_hash).height > blocks.get(state.last_finalized).height,
        local_states' = local_states.set(v, { ...state, last_finalized: cm.block_hash }),
        global_finalized' = global_finalized.union(ancestors_of(cm.block_hash, blocks)),
        blocks' = blocks, next_hash' = next_hash, network' = network,
        justifications' = justifications, connected' = connected,
        slashed' = slashed, logical_clock' = logical_clock,
        commit_messages' = commit_messages, primary_messages' = primary_messages,
        catchup_requests' = catchup_requests, catchup_responses' = catchup_responses,
      }
    }
  }

  // --- CATCH-UP PROTOCOL ---

  // Request catch-up from a peer at a higher round
  action request_catchup(v: Validator): bool = {
    val state = local_states.get(v)
    nondet peer = VALIDATORS.oneOf()
    val peer_state = local_states.get(peer)
    all {
      HONEST.contains(v),
      not(slashed.contains(v)),
      connected.get(v).contains(peer),
      peer_state.round > state.round + 1,
      catchup_requests' = catchup_requests.union(Set({ from: v, to: peer, round: state.round })),
      blocks' = blocks, next_hash' = next_hash, local_states' = local_states,
      network' = network, justifications' = justifications, connected' = connected,
      global_finalized' = global_finalized, slashed' = slashed,
      logical_clock' = logical_clock, commit_messages' = commit_messages,
      primary_messages' = primary_messages, catchup_responses' = catchup_responses,
    }
  }

  // Peer responds to catch-up request with votes from their last completed round
  action respond_catchup = all {
    catchup_requests.size() > 0,
    nondet req = catchup_requests.oneOf()
    val responder = req.to
    val responder_state = local_states.get(responder)
    val resp_round = responder_state.round - 1
    val responder_view = view(responder, network, connected)
    val round_prevotes = responder_view.filter(vote => vote.round == resp_round and vote.kind == Prevote)
    val round_precommits = responder_view.filter(vote => vote.round == resp_round and vote.kind == Precommit)
    all {
      resp_round > req.round,
      catchup_responses' = catchup_responses.union(Set({
        round: resp_round,
        prevotes: round_prevotes,
        precommits: round_precommits,
        last_finalized: responder_state.last_finalized
      })),
      catchup_requests' = catchup_requests.filter(r => r != req),
      blocks' = blocks, next_hash' = next_hash, local_states' = local_states,
      network' = network, justifications' = justifications, connected' = connected,
      global_finalized' = global_finalized, slashed' = slashed,
      logical_clock' = logical_clock, commit_messages' = commit_messages,
      primary_messages' = primary_messages,
    }
  }

  // Process catch-up response: jump to the appropriate round using received justification
  action process_catchup(v: Validator): bool = {
    val state = local_states.get(v)
    all {
      catchup_responses.size() > 0,
      nondet resp = catchup_responses.oneOf()
      // Verify precommits contain a valid justification: some block has >= THRESHOLD
      // precommit voters for it (or its descendants) in the response round
      val has_valid_justification = blocks.keys().exists(b =>
        resp.precommits.filter(vote =>
          vote.kind == Precommit and vote.round == resp.round
          and is_ancestor(b, vote.block_hash, blocks)
        ).map(vote => vote.voter).size() >= THRESHOLD
      )
      all {
        HONEST.contains(v),
        not(slashed.contains(v)),
        resp.round > state.round,
        has_valid_justification,
        resp.round + 1 <= MAX_ROUND,
        val new_finalized = if (blocks.keys().contains(resp.last_finalized)
                                and blocks.get(resp.last_finalized).height > blocks.get(state.last_finalized).height)
                            resp.last_finalized
                            else state.last_finalized
        all {
          // Add received votes to network
          network' = network.union(resp.prevotes).union(resp.precommits),
          local_states' = local_states.set(v, {
            round: resp.round + 1,
            phase: WaitingForPrimary,
            last_finalized: new_finalized,
            prevote_ghost: 0,
            estimate: 0,
            received_primary_estimate: NO_ESTIMATE,
            completable: false,
            round_start_time: logical_clock
          }),
          global_finalized' = global_finalized.union(ancestors_of(new_finalized, blocks)),
          blocks' = blocks, next_hash' = next_hash,
          justifications' = justifications, connected' = connected,
          slashed' = slashed, logical_clock' = logical_clock,
          commit_messages' = commit_messages, primary_messages' = primary_messages,
          catchup_requests' = catchup_requests, catchup_responses' = catchup_responses,
        }
      }
    }
  }

  // --- MALICIOUS BEHAVIOR ---

  // Malicious validator equivocates (sends conflicting votes)
  action malicious_equivocate(v: Validator): bool = {
    nondet b1 = blocks.keys().oneOf()
    nondet b2 = blocks.keys().oneOf()
    nondet k = Set(Prevote, Precommit).oneOf()
    nondet r = 1.to(MAX_ROUND).oneOf()
    all {
      MALICIOUS.contains(v),
      b1 != b2,
      not(slashed.contains(v)),
      network' = network.union(Set(
        { voter: v, round: r, block_hash: b1, kind: k },
        { voter: v, round: r, block_hash: b2, kind: k }
      )),
      blocks' = blocks, next_hash' = next_hash, local_states' = local_states,
      justifications' = justifications, global_finalized' = global_finalized,
      slashed' = slashed, connected' = connected,
      logical_clock' = logical_clock, commit_messages' = commit_messages,
      primary_messages' = primary_messages, catchup_requests' = catchup_requests,
      catchup_responses' = catchup_responses,
    }
  }

  // Detection and Slashing (global view for simplicity)
  action detect_and_slash = {
    val newly_detected = VALIDATORS.filter(v => has_equivocated(network, v))
    all {
      newly_detected.size() > 0,
      slashed' = slashed.union(newly_detected),
      blocks' = blocks, next_hash' = next_hash, local_states' = local_states,
      network' = network, justifications' = justifications, global_finalized' = global_finalized,
      connected' = connected, logical_clock' = logical_clock,
      commit_messages' = commit_messages, primary_messages' = primary_messages,
      catchup_requests' = catchup_requests, catchup_responses' = catchup_responses,
    }
  }

  // --- STEP ---
  action step = any {
    produce_block,
    partition_network,
    heal_network,
    tick_clock,
    respond_catchup,
    detect_and_slash,
    nondet v = VALIDATORS.oneOf()
    any {
      primary_broadcast(v),
      receive_primary_estimate(v),
      timeout_waiting_for_primary(v),
      honest_prevote(v),
      honest_precommit(v),
      honest_finalize_and_advance(v),
      timer_advance_round(v),
      finalize_from_commit(v),
      request_catchup(v),
      process_catchup(v),
      malicious_equivocate(v),
    }
  }

  // --- INVARIANTS ---

  // Safety: no two finalized blocks at the same height
  val safety = global_finalized.forall(b1 =>
    global_finalized.forall(b2 =>
      (blocks.keys().contains(b1) and blocks.keys().contains(b2)
       and blocks.get(b1).height == blocks.get(b2).height) implies (b1 == b2)
    )
  )

  // Accountable Safety: safety violation implies > F equivocators
  val accountable_safety =
    not(safety) implies (VALIDATORS.filter(v => has_equivocated(network, v)).size() > F)

  // GHOST always extends last finalized block
  val ghost_extends_finalized = VALIDATORS.forall(v => {
    val state = local_states.get(v)
    val my_view = view(v, network, connected)
    val g = ghost(state.round, my_view, blocks, state.last_finalized)
    is_ancestor(state.last_finalized, g, blocks)
  })

  // Every commit message has a valid supermajority
  val valid_commits = commit_messages.forall(cm =>
    cm.precommits.filter(vote =>
      is_ancestor(cm.block_hash, vote.block_hash, blocks)
    ).map(vote => vote.voter).size() >= THRESHOLD
  )

  // No honest validator equivocates
  val no_honest_equivocation = HONEST.forall(v => not(has_equivocated(network, v)))

  // Consistency of justifications
  val valid_justifications = justifications.forall(j =>
    j.signatures.size() >= THRESHOLD
  )
}
