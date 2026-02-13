//                                                                          -*- quint -*-

module sassafras {
  // --- TYPES & CONSTANTS ---
  type Validator = str
  type Block = { slot: int, author: Validator }

  pure val VALIDATORS: Set[Validator] = Set("Alice", "Bob", "Charlie", "Dave")
  pure val EPOCH_LENGTH: int = 3

  // --- STATE VARIABLES ---
  var phase: str                  // Protocol phase: "SUBMIT", "SORT", "PRODUCE", "DONE"
  var schedule: int -> Validator  // Secret map: slot -> Validator
  var chain: Set[Block]           // Set of blocks produced and added to the ledger
  var current_slot: int           // Current time slot

  // --- INITIALIZATION ---
  action init = all {
    phase' = "SUBMIT",
    schedule' = Map(),
    chain' = Set(),
    current_slot' = 1,
  }

  // --- ACTIONS (STATE TRANSITIONS) ---

  // Phase 1: Validators submit anonymous Ring-VRF tickets.
  action submit_tickets = all {
    phase == "SUBMIT",
    phase' = "SORT",
    schedule' = schedule,
    chain' = chain,
    current_slot' = current_slot,
  }

  // Phase 2: Tickets are cryptographically sorted.
  // We model the cryptographic guarantee: Sassafras ensures exactly ONE
  // valid validator is secretly assigned per slot for the entire epoch.
  action sort_tickets = {
    nondet v1 = VALIDATORS.oneOf()
    nondet v2 = VALIDATORS.oneOf()
    nondet v3 = VALIDATORS.oneOf()
    all {
      phase == "SORT",
      // Map each slot in the epoch to a uniquely selected validator
      schedule' = Map().put(1, v1).put(2, v2).put(3, v3),
      phase' = "PRODUCE",
      chain' = chain,
      current_slot' = current_slot,
    }
  }

  // Phase 3: Block Production
  // The uniquely scheduled leader reveals themselves to author the block.
  action produce_block = all {
    phase == "PRODUCE",
    current_slot <= EPOCH_LENGTH,

    // The cryptographically assigned leader is the only one who can validly produce a block
    chain' = chain.union(Set({ slot: current_slot, author: schedule.get(current_slot) })),

    // Advance time
    current_slot' = current_slot + 1,

    // Transition to DONE if the epoch is finished, otherwise keep producing
    phase' = if (current_slot + 1 > EPOCH_LENGTH) "DONE" else "PRODUCE",
    schedule' = schedule,
  }

  // Define the valid transitions of the system
  action step = any {
    submit_tickets,
    sort_tickets,
    produce_block,
    idle
  }

  // Phase 4: Idle (Stuttering step)
  // Once the epoch is done, the system rests. This prevents the "Deadlock" error.
  action idle = all {
    phase == "DONE",

    // Keep all variables exactly the same
    phase' = phase,
    schedule' = schedule,
    chain' = chain,
    current_slot' = current_slot,
  }

  // ==========================================
  // --- INVARIANTS (CORRECTNESS PROPERTIES) ---
  // ==========================================

  // Property 1: Safety (No Forks)
  // Because Sassafras mathematically enforces one producer per slot, we
  // should NEVER see two different blocks/authors at the same slot.
  val no_forks_inv =
    chain.forall(b1 =>
      chain.forall(b2 =>
        (b1.slot == b2.slot) implies (b1.author == b2.author)
      )
    )

  // Property 2: Liveness (Constant-Time Production)
  // Eliminates BABE's "empty slots". At the end of the epoch, every slot
  // must have exactly one block.
  val constant_time_inv =
    (phase == "DONE") implies (chain.size() == EPOCH_LENGTH)

  // Property 3: Authorization
  // Every block on the chain must have been authored by the strictly
  // scheduled secret leader for that exact slot.
  val valid_producer_inv =
    chain.forall(b => schedule.get(b.slot) == b.author)
}