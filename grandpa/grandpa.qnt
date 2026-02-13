//                                                                          -*- quint -*-

module grandpa {
    type Block = { hash: int, parent: int, height: int }
    type Vote = { voter: int, round: int, blockHash: int, kind: str }

    val VALIDATORS = Set(1, 2, 3, 4)
    val THRESHOLD = 3 // 2f + 1
    val MAX_HEIGHT = 3
    val MAX_ROUND = 1

    var dag: int -> Block
    var votes: Set[Vote]
    var finalized: Set[int]
    var partition: Set[Set[int]]
    var inflight_messages: Set[Vote]
    var network: int -> Set[Vote]

    // --- 1. GHOST / Ancestry Logic ---
    pure def is_ancestor(target: int, voted: int, tree: int -> Block): bool = {
        val steps = Set(0, 1, 2, 3)
        val final_pos = steps.fold(voted, (curr, step) => {
            if (curr == target) curr
            else tree.get(curr).parent
        })
        final_pos == target
    }

    // Helper to count votes for a block AND all its descendants
    pure def count_votes(target_b: int, r: int, k: str, v_set: Set[Vote], tree: int -> Block): int = {
        v_set.filter(v =>
            v.kind == k and v.round == r and is_ancestor(target_b, v.blockHash, tree)
        ).map(v => v.voter).size()
    }

    // --- 2. Initialization ---
    action init: bool = all {
        dag' = Map(0 -> { hash: 0, parent: 0, height: 0 }),
        votes' = Set(),
        finalized' = Set(0),
        partition' = Set(VALIDATORS),
        inflight_messages' = Set(),
        network' = VALIDATORS.mapBy(_v => Set()),
    }

    // --- 3. Actions ---

    // Honest GHOST-based Voting (uses local network view)
    action cast_honest_vote(v: int, r: int): bool = {
        val local_votes = network.get(v)
        // GHOST Rule: Find the highest block with > 2/3 prevotes in local view
        val best_candidate = dag.keys().filter(b =>
            count_votes(b, r, "prevote", local_votes, dag) >= THRESHOLD
        ).fold(0, (max_b, curr_b) =>
            if (dag.get(curr_b).height > dag.get(max_b).height) curr_b else max_b
        )

        val new_vote = { voter: v, round: r, blockHash: best_candidate, kind: "pre-commit" }
        val local_with_new = local_votes.union(Set(new_vote))
        val newly_finalized = dag.keys().filter(candidate =>
            count_votes(candidate, r, "pre-commit", local_with_new, dag) >= THRESHOLD
        )

        all {
	    VALIDATORS.contains(v),
            not(votes.exists(vote => vote.voter == v and vote.round == r and vote.kind == "pre-commit")),
            votes' = votes.union(Set(new_vote)),
            inflight_messages' = inflight_messages.union(Set(new_vote)),
            network' = network.put(v, local_with_new),
            finalized' = finalized.union(newly_finalized),
            dag' = dag,
            partition' = partition,
        }
    }

    // Byzantine Equivocation
    action equivocate(v: int, r: int, b1: int, b2: int): bool = {
        // The attacker sends two conflicting pre-commits
        val attacker_votes = Set(
            { voter: v, round: r, blockHash: b1, kind: "pre-commit" },
            { voter: v, round: r, blockHash: b2, kind: "pre-commit" }
        )
        val local_with_new = network.get(v).union(attacker_votes)
        val newly_finalized = dag.keys().filter(candidate =>
            count_votes(candidate, r, "pre-commit", local_with_new, dag) >= THRESHOLD
        )
        all {
	    VALIDATORS.contains(v),
            b1 != b2,
            dag.keys().contains(b1),
            dag.keys().contains(b2),
            votes' = votes.union(attacker_votes),
            inflight_messages' = inflight_messages.union(attacker_votes),
            network' = network.put(v, local_with_new),
            finalized' = finalized.union(newly_finalized),
            dag' = dag,
            partition' = partition,
        }
    }

    action produce_block(p: int, h: int): bool = all {
        dag.keys().contains(p),
        not(dag.keys().contains(h)),
        dag' = dag.put(h, { hash: h, parent: p, height: dag.get(p).height + 1 }),
        votes' = votes,
        finalized' = finalized,
        partition' = partition,
        inflight_messages' = inflight_messages,
        network' = network,
    }

    // --- 4. Network Partition ---

    action create_partition(group1: Set[int], group2: Set[int]): bool = all {
        group1.union(group2) == VALIDATORS,
        group1.intersect(group2) == Set(),
        partition' = Set(group1, group2),
        dag' = dag,
        votes' = votes,
        finalized' = finalized,
        inflight_messages' = inflight_messages,
        network' = network,
    }

    action deliver_message(v: int, msg: Vote): bool = {
        // Only deliver if sender and receiver are in the same partition group
        val sender_group = partition.filter(g => g.contains(msg.voter)).flatten()
        val receiver_group = partition.filter(g => g.contains(v)).flatten()
        val updated_local = network.get(v).union(Set(msg))
        val newly_finalized = dag.keys().filter(candidate =>
            count_votes(candidate, msg.round, "pre-commit", updated_local, dag) >= THRESHOLD
        )
        all {
            inflight_messages.contains(msg),
            sender_group == receiver_group,
            network' = network.put(v, updated_local),
	    // One thing to note: deliver_message removes the message from inflight_messages on delivery,
	    // so each vote can only be delivered to one validator. If you want broadcast semantics
	    // (multiple validators can receive the same vote), change to inflight_messages' = inflight_messages,.
	    // inflight_messages' = inflight_messages.exclude(Set(msg)),
            inflight_messages' = inflight_messages, // .exclude(Set(msg)),
            finalized' = finalized.union(newly_finalized),
            dag' = dag,
            votes' = votes,
            partition' = partition,
        }
    }

    // --- 5. Step ---

    action step: bool = any {
        nondet p = dag.keys().oneOf()
        nondet h = 1.to(MAX_HEIGHT).oneOf()
        produce_block(p, h),

        nondet v = VALIDATORS.oneOf()
        nondet r = 1.to(MAX_ROUND).oneOf()
        cast_honest_vote(v, r),

        nondet v_bad = VALIDATORS.oneOf()
        nondet b1 = dag.keys().oneOf()
        nondet b2 = dag.keys().oneOf()
        equivocate(v_bad, 1, b1, b2),

        nondet group1 = VALIDATORS.powerset().oneOf()
        create_partition(group1, VALIDATORS.exclude(group1)),

        nondet v_recv = VALIDATORS.oneOf()
        nondet msg = inflight_messages.oneOf()
        deliver_message(v_recv, msg),
    }

    // --- 6. Invariants ---
    val SafetyInvariant = finalized.forall(b1 =>
        finalized.forall(b2 =>
            (dag.get(b1).height == dag.get(b2).height) implies (b1 == b2)
        )
    )

    // TODO: No-rollback (finalized set only grows) requires temporal operator support

    val AccountableSafety = {
        val violation = finalized.exists(b1 => finalized.exists(b2 =>
            b1 != b2 and dag.get(b1).height == dag.get(b2).height
        ))
        violation implies (
            VALIDATORS.filter(v =>
                1.to(MAX_ROUND).exists(r =>
                    votes.filter(vote => vote.voter == v and vote.round == r)
                        .map(rv => rv.blockHash).size() > 1
                )
            ).size() >= (VALIDATORS.size() / 3 + 1)
       )
    }

    val JustificationInvariant = finalized.forall(b =>
        b == 0 or finalized.contains(dag.get(b).parent)
    )

    // If no partition group has >= THRESHOLD validators, finalization cannot progress.
    // This is a step-level property: check it holds for each transition.
    val StallingCheck =
        partition.forall(group => group.size() < THRESHOLD)
        implies
        (finalized == Set(0))

}
