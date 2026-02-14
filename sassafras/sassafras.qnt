//                                                                          -*- quint -*-

module sassafras {
  // --- TYPES & CONSTANTS ---
  type Validator = str
  type Ticket = { owner: Validator, vrf_output: int }
  type Block = { slot: int, author: Validator, is_fallback: bool }

  pure val NOBODY: Validator = "NOBODY"
  pure val HONEST: Set[Validator] = Set("Alice", "Bob", "Charlie")
  pure val MALICIOUS: Set[Validator] = Set("Dave")
  pure val VALIDATORS = HONEST.union(MALICIOUS)
  pure val EPOCH_LENGTH: int = 4
  pure val TICKETS_PER_VALIDATOR: int = 2
  pure val TICKET_THRESHOLD: int = 6  // VRF outputs below this qualify
  pure val MAX_VRF: int = 8           // Range of simulated VRF outputs

  // --- STATE VARIABLES ---
  var phase: str                              // "SUBMIT", "PUBLISH", "SORT", "PRODUCE", "DONE"
  var schedule: int -> Validator              // slot -> scheduled leader
  var chain: Set[Block]                       // produced blocks
  var current_slot: int                       // current time slot
  var tickets: Set[Ticket]                    // generated winning tickets
  var published_tickets: Set[Ticket]          // tickets surviving repeater phase
  var online: Set[Validator]                  // validators currently online
  var revealed: Set[Validator]                // validators whose identity was leaked
  var malicious_repeater_tickets: Set[Ticket] // tickets assigned to malicious repeaters

  // --- HELPER FUNCTIONS ---

  // Outside-in slot assignment: [1, N, 2, N-1, 3, N-2, ...]
  pure def outside_in_index(i: int, n: int): int =
    if (i % 2 == 0) i / 2 + 1
    else n - (i - 1) / 2

  // Insert a ticket into a sorted list (by vrf_output, ascending)
  pure def insert_sorted(lst: List[Ticket], t: Ticket): List[Ticket] =
    lst.select(x => x.vrf_output <= t.vrf_output)
      .append(t)
      .concat(lst.select(x => x.vrf_output > t.vrf_output))

  // Sort tickets by VRF output (ascending)
  pure def sort_by_vrf(ts: Set[Ticket]): List[Ticket] =
    ts.fold([], (acc, t) => insert_sorted(acc, t))

  // Convert sorted ticket list to schedule map using outside-in assignment
  // Uses static range 0.to(TICKET_THRESHOLD - 1) for Apalache compatibility.
  pure def tickets_to_schedule(sorted: List[Ticket], epoch_len: int): int -> Validator = {
    val assigned = 0.to(TICKET_THRESHOLD - 1).fold(Map(), (sched, i) =>
      if (i < sorted.length() and i < epoch_len)
        sched.put(outside_in_index(i, epoch_len), sorted.nth(i).owner)
      else sched
    )
    // Fill remaining slots with NOBODY (fallback territory)
    1.to(epoch_len).fold(assigned, (sched, slot) =>
      if (sched.keys().contains(slot)) sched
      else sched.put(slot, NOBODY)
    )
  }

  // --- INITIALIZATION ---
  action init = all {
    phase' = "SUBMIT",
    schedule' = 1.to(EPOCH_LENGTH).fold(Map(), (s, i) => s.put(i, NOBODY)),
    chain' = Set(),
    current_slot' = 1,
    tickets' = Set(),
    published_tickets' = Set(),
    online' = VALIDATORS,
    revealed' = Set(),
    malicious_repeater_tickets' = Set(),
  }

  // --- ACTIONS (STATE TRANSITIONS) ---

  // Phase A — Generate tickets (SUBMIT → PUBLISH)
  // Each VRF value is nondeterministically assigned to a validator or nobody.
  // Only VRF outputs below TICKET_THRESHOLD qualify (ensured by construction).
  action generate_tickets = {
    nondet assign_0 = VALIDATORS.union(Set(NOBODY)).oneOf()
    nondet assign_1 = VALIDATORS.union(Set(NOBODY)).oneOf()
    nondet assign_2 = VALIDATORS.union(Set(NOBODY)).oneOf()
    nondet assign_3 = VALIDATORS.union(Set(NOBODY)).oneOf()
    nondet assign_4 = VALIDATORS.union(Set(NOBODY)).oneOf()
    nondet assign_5 = VALIDATORS.union(Set(NOBODY)).oneOf()
    val assignments = Map()
      .put(0, assign_0).put(1, assign_1).put(2, assign_2)
      .put(3, assign_3).put(4, assign_4).put(5, assign_5)
    val chosen = 0.to(TICKET_THRESHOLD - 1)
      .filter(vrf => assignments.get(vrf) != NOBODY)
      .map(vrf => { owner: assignments.get(vrf), vrf_output: vrf })
    all {
      phase == "SUBMIT",
      // Each validator has at most TICKETS_PER_VALIDATOR winning tickets
      VALIDATORS.forall(v =>
        chosen.filter(t => t.owner == v).size() <= TICKETS_PER_VALIDATOR
      ),
      chosen.size() > 0,
      tickets' = chosen,
      phase' = "PUBLISH",
      published_tickets' = published_tickets,
      online' = online,
      revealed' = revealed,
      schedule' = schedule,
      chain' = chain,
      current_slot' = current_slot,
      malicious_repeater_tickets' = malicious_repeater_tickets,
    }
  }

  // Phase B — Publish tickets through repeaters (PUBLISH → SORT)
  // Honest repeaters always forward; malicious repeaters may drop and reveal owners.
  action publish_tickets = {
    nondet mal_tickets = tickets.powerset().oneOf()
    val honest_tickets_set = tickets.filter(t => not(mal_tickets.contains(t)))
    nondet mal_forwarded = mal_tickets.powerset().oneOf()
    all {
      phase == "PUBLISH",
      published_tickets' = honest_tickets_set.union(mal_forwarded),
      revealed' = revealed.union(mal_tickets.map(t => t.owner)),
      malicious_repeater_tickets' = mal_tickets,
      tickets' = tickets,
      phase' = "SORT",
      online' = online,
      schedule' = schedule,
      chain' = chain,
      current_slot' = current_slot,
    }
  }

  // Phase C — Sort tickets and build schedule (SORT → PRODUCE)
  // Sort by VRF output, assign to slots using outside-in pattern.
  action sort_tickets = {
    val sorted = sort_by_vrf(published_tickets)
    val new_schedule = tickets_to_schedule(sorted, EPOCH_LENGTH)
    // Nondeterministically choose which validators are online for the epoch
    nondet online_set = VALIDATORS.powerset().oneOf()
    all {
      phase == "SORT",
      schedule' = new_schedule,
      online' = online_set,
      phase' = "PRODUCE",
      tickets' = tickets,
      published_tickets' = published_tickets,
      revealed' = revealed,
      chain' = chain,
      current_slot' = current_slot,
      malicious_repeater_tickets' = malicious_repeater_tickets,
    }
  }

  // Phase D — Normal block production
  // The scheduled leader is online and produces the block.
  action produce_normal_block = all {
    phase == "PRODUCE",
    current_slot <= EPOCH_LENGTH,
    schedule.get(current_slot) != NOBODY,
    online.contains(schedule.get(current_slot)),
    chain' = chain.union(Set({ slot: current_slot, author: schedule.get(current_slot), is_fallback: false })),
    current_slot' = current_slot + 1,
    phase' = if (current_slot + 1 > EPOCH_LENGTH) "DONE" else "PRODUCE",
    schedule' = schedule,
    tickets' = tickets,
    published_tickets' = published_tickets,
    revealed' = revealed,
    online' = online,
    malicious_repeater_tickets' = malicious_repeater_tickets,
  }

  // Phase D — Fallback: no scheduled leader for this slot
  action produce_fallback_no_leader = {
    nondet fallback = HONEST.oneOf()
    all {
      phase == "PRODUCE",
      current_slot <= EPOCH_LENGTH,
      schedule.get(current_slot) == NOBODY,
      online.contains(fallback),
      chain' = chain.union(Set({ slot: current_slot, author: fallback, is_fallback: true })),
      current_slot' = current_slot + 1,
      phase' = if (current_slot + 1 > EPOCH_LENGTH) "DONE" else "PRODUCE",
      schedule' = schedule,
      tickets' = tickets,
      published_tickets' = published_tickets,
      revealed' = revealed,
      online' = online,
      malicious_repeater_tickets' = malicious_repeater_tickets,
    }
  }

  // Phase D — Fallback: scheduled leader is offline
  action produce_fallback_offline = {
    nondet fallback = HONEST.oneOf()
    all {
      phase == "PRODUCE",
      current_slot <= EPOCH_LENGTH,
      schedule.get(current_slot) != NOBODY,
      not(online.contains(schedule.get(current_slot))),
      online.contains(fallback),
      chain' = chain.union(Set({ slot: current_slot, author: fallback, is_fallback: true })),
      current_slot' = current_slot + 1,
      phase' = if (current_slot + 1 > EPOCH_LENGTH) "DONE" else "PRODUCE",
      schedule' = schedule,
      tickets' = tickets,
      published_tickets' = published_tickets,
      revealed' = revealed,
      online' = online,
      malicious_repeater_tickets' = malicious_repeater_tickets,
    }
  }

  // Phase D — Skip slot: no one available to produce
  action skip_slot = all {
    phase == "PRODUCE",
    current_slot <= EPOCH_LENGTH,
    or {
      schedule.get(current_slot) == NOBODY,
      not(online.contains(schedule.get(current_slot))),
    },
    HONEST.forall(v => not(online.contains(v))),
    chain' = chain,
    current_slot' = current_slot + 1,
    phase' = if (current_slot + 1 > EPOCH_LENGTH) "DONE" else "PRODUCE",
    schedule' = schedule,
    tickets' = tickets,
    published_tickets' = published_tickets,
    revealed' = revealed,
    online' = online,
    malicious_repeater_tickets' = malicious_repeater_tickets,
  }

  action produce_block = any {
    produce_normal_block,
    produce_fallback_no_leader,
    produce_fallback_offline,
    skip_slot,
  }

  // Idle (stuttering step) — prevents deadlock after epoch ends
  action idle = all {
    phase == "DONE",
    phase' = phase,
    schedule' = schedule,
    chain' = chain,
    current_slot' = current_slot,
    tickets' = tickets,
    published_tickets' = published_tickets,
    online' = online,
    revealed' = revealed,
    malicious_repeater_tickets' = malicious_repeater_tickets,
  }

  // --- STATE TRANSITIONS ---
  action step = any {
    generate_tickets,
    publish_tickets,
    sort_tickets,
    produce_block,
    idle,
  }

  // ==========================================
  // --- INVARIANTS (CORRECTNESS PROPERTIES) ---
  // ==========================================

  // Safety: No forks — at most one block per slot
  val no_forks_inv =
    chain.forall(b1 =>
      chain.forall(b2 =>
        (b1.slot == b2.slot) implies (b1.author == b2.author)
      )
    )

  // Liveness: Constant-time production — every slot filled at epoch end
  val constant_time_inv =
    (phase == "DONE") implies (chain.size() == EPOCH_LENGTH)

  // Authorization: Normal blocks must match schedule; fallback blocks must have honest author
  val valid_producer_inv =
    chain.forall(b =>
      if (b.is_fallback) HONEST.contains(b.author)
      else schedule.get(b.slot) == b.author
    )

  // Anonymity: Only malicious repeaters can leak validator identities
  val anonymity_inv =
    revealed.forall(v =>
      malicious_repeater_tickets.exists(t => t.owner == v)
    )

  // Fallback safety: Fallback blocks only when scheduled leader is unavailable
  val fallback_safety_inv =
    chain.forall(b =>
      b.is_fallback implies (
        schedule.get(b.slot) == NOBODY or not(online.contains(schedule.get(b.slot)))
      )
    )

  // Ticket uniqueness: No two published tickets share a VRF output
  val ticket_uniqueness_inv =
    published_tickets.forall(t1 =>
      published_tickets.forall(t2 =>
        (t1 != t2) implies (t1.vrf_output != t2.vrf_output)
      )
    )

  // Honest leader secrecy: Honest validators with honest repeaters stay hidden
  val honest_leader_secrecy_inv =
    HONEST.forall(v =>
      not(malicious_repeater_tickets.exists(t => t.owner == v))
        implies not(revealed.contains(v))
    )
}
