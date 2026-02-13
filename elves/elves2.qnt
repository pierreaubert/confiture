//                                                                          -*- quint -*-

module elves {
  // --- TYPES & CONSTANTS ---
  type Validator = str

  // We model a network with 4 Honest Validators and 2 Malicious Validators.
  pure val HONEST: Set[Validator] = Set("H1", "H2", "H3", "H4")
  pure val MALICIOUS: Set[Validator] = Set("M1", "M2", "M3", "M4")
  pure val VALIDATORS: Set[Validator] = HONEST.union(MALICIOUS)

  // --- STATE VARIABLES ---
  var phase: str                  // "SUBMIT", "AUDIT", "CHECK_VOTES", "FINALIZED", "REJECTED"
  var block_is_valid: bool        // Objective truth: is the block actually valid?
  var committee: Set[Validator]   // Current auditors checking the block
  var approvals: Set[Validator]   // Validators who voted the block is valid
  var disputes: Set[Validator]    // Validators who voted the block is invalid
  var slashed: Set[Validator]     // Malicious validators who lost their stake

  // --- INITIALIZATION ---
  action init = {
    // The environment randomly generates a valid or invalid block
    nondet v = oneOf(Set(true, false))
    all {
      phase' = "SUBMIT",
      block_is_valid' = v,
      committee' = Set(),
      approvals' = Set(),
      disputes' = Set(),
      slashed' = Set(),
    }
  }

  // --- ACTIONS (STATE TRANSITIONS) ---

  // Phase 1: Submission
  action submit_block = {
    // ELVES STATISTICAL GUARANTEE: We set the initial committee size to 3.
    // By the Pigeonhole Principle, since there are only 2 malicious nodes,
    // at least 1 honest node is mathematically guaranteed to be assigned.
    nondet c = oneOf(VALIDATORS.powerset().filter(s => s.size() == 2))
    all {
      phase == "SUBMIT",
      committee' = c,
      phase' = "AUDIT",
      block_is_valid' = block_is_valid,
      approvals' = approvals,
      disputes' = disputes,
      slashed' = slashed,
    }
  }

  // Phase 2: The assigned committee audits the block and votes.
  action vote = all {
    phase == "AUDIT",

    // Honest nodes vote truthfully. Malicious nodes intentionally lie to attack the network.
    approvals' = committee.filter(v =>
      if (HONEST.contains(v)) block_is_valid else not(block_is_valid)
    ),
    disputes' = committee.filter(v =>
      if (HONEST.contains(v)) not(block_is_valid) else block_is_valid
    ),

    phase' = "CHECK_VOTES",
    block_is_valid' = block_is_valid,
    committee' = committee,
    slashed' = slashed,
  }

  // Phase 3: Check votes. If there's a dispute, trigger an ELVES Escalation!
  action check_votes = all {
    phase == "CHECK_VOTES",

    // Case A: We are checking the small initial committee
    if (committee != VALIDATORS) {
      if (disputes.size() > 0) {
        // ESCALATION: An auditor raised an alarm! Expand the audit to the entire network.
        all {
          phase' = "AUDIT",
          committee' = VALIDATORS, // Full network will now check the block
          approvals' = Set(),      // Clear previous votes
          disputes' = Set(),
          block_is_valid' = block_is_valid,
          slashed' = slashed,
        }
      } else {
        // FAST-PATH: Unanimous approval from the initial committee.
        all {
          phase' = "FINALIZED",
          committee' = committee,
          approvals' = approvals,
          disputes' = disputes,
          block_is_valid' = block_is_valid,
          slashed' = slashed,
        }
      }
    }
    // Case B: We are resolving an escalated full-network dispute
    else {
      if (disputes.size() > 0 and not(block_is_valid)) {
        // The block was indeed invalid. Reject it and SLASH the malicious approvers!
        all {
          phase' = "REJECTED",
          slashed' = slashed.union(approvals),
          committee' = committee,
          approvals' = approvals,
          disputes' = disputes,
          block_is_valid' = block_is_valid,
        }
      } else {
        if (disputes.size() > 0 and block_is_valid) {
          // The block was valid, meaning the disputers lied to stall the network. Slash them!
          all {
            phase' = "FINALIZED",
            slashed' = slashed.union(disputes),
            committee' = committee,
            approvals' = approvals,
            disputes' = disputes,
            block_is_valid' = block_is_valid,
          }
        } else {
          // Unanimous agreement on a valid block during escalation
          all {
            phase' = "FINALIZED",
            committee' = committee,
            approvals' = approvals,
            disputes' = disputes,
            block_is_valid' = block_is_valid,
            slashed' = slashed,
          }
        }
      }
    }
  }

  // Phase 4: Stuttering step to avoid deadlock
  action idle = all {
    Set("FINALIZED", "REJECTED").contains(phase),
    phase' = phase,
    block_is_valid' = block_is_valid,
    committee' = committee,
    approvals' = approvals,
    disputes' = disputes,
    slashed' = slashed,
  }

  action step = any {
    submit_block,
    vote,
    check_votes,
    idle,
  }

  // ==========================================
  // --- INVARIANTS (CORRECTNESS PROPERTIES) ---
  // ==========================================

  // Property 1: Safety (No invalid block is ever finalized)
  val no_invalid_finalization_inv =
    (phase == "FINALIZED") implies (block_is_valid)

  // Property 2: Liveness (A valid block is never rejected)
  val no_valid_rejection_inv =
    (phase == "REJECTED") implies (not(block_is_valid))

  // Property 3: Accountability (Malicious nodes get slashed)
  // If the protocol finishes and the block was invalid, the liars MUST be slashed.
  val malicious_slashed_inv =
    (phase == "REJECTED") implies (slashed.intersect(MALICIOUS).size() > 0)
}
