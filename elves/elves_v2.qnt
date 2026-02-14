//                                                                          -*- quint -*-

module elves_v3 {
  // ==========================================================================
  // TYPES
  // ==========================================================================
  type CandidateStatus = 
      Seconded 
    | Backable 
    | PendingAvailability 
    | Available
    | ApprovalPending 
    | Approved 
    | Disputed 
    | Finalized 
    | Rejected

  type CandidateValidity = Valid | Invalid

  type Candidate = {
    id: int,
    core: int,
    validity: CandidateValidity,
    status: CandidateStatus,
    backer_votes_for: Set[int],
    backer_votes_against: Set[int],
    availability_attestations: Set[int],
    approval_assignments: int -> Set[int],
    approval_votes_for: Set[int],
    approval_votes_against: Set[int],
    no_shows: Set[int],
    current_tranche: int,
    tranche_start_time: int, // Clock time when the tranche was assigned
    dispute_votes_for: Set[int],
    dispute_votes_against: Set[int]
  }

  // ==========================================================================
  // CONSTANTS
  // ==========================================================================
  pure val VALIDATORS: Set[int] = 0.to(9)
  pure val HONEST: Set[int] = 0.to(6)
  pure val MALICIOUS: Set[int] = Set(7, 8, 9)
  pure val CORES: Set[int] = Set(0, 1) // Reduced cores for state space
  
  pure val BACKING_THRESHOLD: int = 2
  pure val AVAILABILITY_THRESHOLD: int = 7
  pure val APPROVAL_TRANCHES: int = 3
  pure val CHECKERS_PER_TRANCHE: int = 2
  pure val DISPUTE_THRESHOLD: int = 7
  
  pure val TRANCHE_TIMEOUT: int = 2 // Time steps before a tranche can escalate if no-show
  pure val MAX_TIME: int = 15
  pure val MAX_CANDIDATES: int = 2

  // ==========================================================================
  // HELPERS
  // ==========================================================================
  pure def is_honest(v: int): bool = HONEST.contains(v)

  pure def is_terminal(status: CandidateStatus): bool =
    status == Finalized or status == Rejected

  pure def votes_valid(v: int, validity: CandidateValidity): bool =
    if (is_honest(v)) validity == Valid
    else validity == Invalid

  // ==========================================================================
  // STATE VARIABLES
  // ==========================================================================
  var candidates: int -> Candidate
  var backing_groups: int -> Set[int]
  var next_candidate_id: int
  var slashed: Set[int]
  var clock: int

  // ==========================================================================
  // INITIALIZATION
  // ==========================================================================
  action init = all {
    candidates' = Map(),
    backing_groups' = Map()
      .put(0, Set(0, 1, 2))
      .put(1, Set(3, 4, 5)),
    next_candidate_id' = 0,
    slashed' = Set(),
    clock' = 0,
  }

  // ==========================================================================
  // ACTIONS
  // ==========================================================================

  action tick = all {
    clock < MAX_TIME,
    clock' = clock + 1,
    candidates' = candidates,
    backing_groups' = backing_groups,
    next_candidate_id' = next_candidate_id,
    slashed' = slashed,
  }

  action submit_candidate = {
    nondet core = CORES.oneOf()
    nondet validity = Set(Valid, Invalid).oneOf()
    all {
      candidates.keys().forall(id =>
        candidates.get(id).core != core or is_terminal(candidates.get(id).status)
      ),
      next_candidate_id < MAX_CANDIDATES,
      candidates' = candidates.put(next_candidate_id, {
        id: next_candidate_id,
        core: core,
        validity: validity,
        status: Seconded,
        backer_votes_for: Set(),
        backer_votes_against: Set(),
        availability_attestations: Set(),
        approval_assignments: Map(),
        approval_votes_for: Set(),
        approval_votes_against: Set(),
        no_shows: Set(),
        current_tranche: 0,
        tranche_start_time: 0,
        dispute_votes_for: Set(),
        dispute_votes_against: Set(),
      }),
      next_candidate_id' = next_candidate_id + 1,
      backing_groups' = backing_groups,
      slashed' = slashed,
      clock' = clock,
    }
  }

  action backing_vote = {
    nondet cid = candidates.keys().oneOf()
    val c = candidates.get(cid)
    val eligible_backers = backing_groups.get(c.core)
      .exclude(c.backer_votes_for)
      .exclude(c.backer_votes_against)
    all {
      c.status == Seconded,
      eligible_backers.size() > 0,
      nondet v = eligible_backers.oneOf(),
      val vote_for = votes_valid(v, c.validity),
      val new_for = if (vote_for) c.backer_votes_for.union(Set(v)) else c.backer_votes_for,
      val new_against = if (not(vote_for)) c.backer_votes_against.union(Set(v)) else c.backer_votes_against,
      val new_status = if (new_for.size() >= BACKING_THRESHOLD) Backable else Seconded,
      candidates' = candidates.put(cid, { ...c,
        backer_votes_for: new_for,
        backer_votes_against: new_against,
        status: new_status,
      }),
      backing_groups' = backing_groups,
      next_candidate_id' = next_candidate_id,
      slashed' = slashed,
      clock' = clock,
    }
  }

  action include_candidate = {
    nondet cid = candidates.keys().oneOf()
    val c = candidates.get(cid)
    all {
      c.status == Backable,
      candidates' = candidates.put(cid, { ...c, status: PendingAvailability }),
      backing_groups' = backing_groups,
      next_candidate_id' = next_candidate_id,
      slashed' = slashed,
      clock' = clock,
    }
  }

  action attest_availability = {
    nondet cid = candidates.keys().oneOf()
    val c = candidates.get(cid)
    val eligible = VALIDATORS.exclude(c.availability_attestations)
    all {
      c.status == PendingAvailability,
      eligible.size() > 0,
      nondet v = eligible.oneOf(),
      val new_att = c.availability_attestations.union(Set(v)),
      val new_status = if (new_att.size() >= AVAILABILITY_THRESHOLD) Available else PendingAvailability,
      candidates' = candidates.put(cid, { ...c,
        availability_attestations: new_att,
        status: new_status,
      }),
      backing_groups' = backing_groups,
      next_candidate_id' = next_candidate_id,
      slashed' = slashed,
      clock' = clock,
    }
  }

  action assign_approval_tranche = {
    nondet cid = candidates.keys().oneOf()
    val c = candidates.get(cid)
    val t = c.current_tranche
    all {
      (c.status == Available or c.status == ApprovalPending),
      not(c.approval_assignments.keys().contains(t)),
      t < APPROVAL_TRANCHES,
      nondet checkers = VALIDATORS.powerset().filter(s => s.size() == CHECKERS_PER_TRANCHE).oneOf(),
      candidates' = candidates.put(cid, { ...c,
        approval_assignments: c.approval_assignments.put(t, checkers),
        status: ApprovalPending,
        tranche_start_time: clock
      }),
      backing_groups' = backing_groups,
      next_candidate_id' = next_candidate_id,
      slashed' = slashed,
      clock' = clock,
    }
  }

  action approval_vote = {
    nondet cid = candidates.keys().oneOf()
    val c = candidates.get(cid)
    val t = c.current_tranche
    val checkers = if (c.approval_assignments.keys().contains(t)) c.approval_assignments.get(t) else Set()
    val eligible = checkers.exclude(c.approval_votes_for).exclude(c.approval_votes_against).exclude(c.no_shows)
    all {
      c.status == ApprovalPending,
      eligible.size() > 0,
      nondet v = eligible.oneOf(),
      val vote_for = votes_valid(v, c.validity),
      val new_for = if (vote_for) c.approval_votes_for.union(Set(v)) else c.approval_votes_for,
      val new_against = if (not(vote_for)) c.approval_votes_against.union(Set(v)) else c.approval_votes_against,
      // If any checker votes against, it immediately triggers Disputed status
      val new_status = if (new_against.size() > 0) Disputed 
                       else if (new_for.size() == CHECKERS_PER_TRANCHE * (c.current_tranche + 1)) Approved 
                       else ApprovalPending,
      candidates' = candidates.put(cid, { ...c,
        approval_votes_for: new_for,
        approval_votes_against: new_against,
        status: new_status,
      }),
      backing_groups' = backing_groups,
      next_candidate_id' = next_candidate_id,
      slashed' = slashed,
      clock' = clock,
    }
  }

  action escalate_tranche = {
    nondet cid = candidates.keys().oneOf()
    val c = candidates.get(cid)
    all {
      c.status == ApprovalPending,
      clock >= c.tranche_start_time + TRANCHE_TIMEOUT,
      c.current_tranche + 1 < APPROVAL_TRANCHES,
      candidates' = candidates.put(cid, { ...c,
        current_tranche: c.current_tranche + 1,
        // Modeling that some checkers from the previous tranche were no-shows
        no_shows: c.no_shows.union(c.approval_assignments.get(c.current_tranche).exclude(c.approval_votes_for).exclude(c.approval_votes_against))
      }),
      backing_groups' = backing_groups,
      next_candidate_id' = next_candidate_id,
      slashed' = slashed,
      clock' = clock,
    }
  }

  action resolve_approved = {
    nondet cid = candidates.keys().oneOf()
    val c = candidates.get(cid)
    all {
      c.status == Approved,
      candidates' = candidates.put(cid, { ...c, status: Finalized }),
      backing_groups' = backing_groups,
      next_candidate_id' = next_candidate_id,
      slashed' = slashed,
      clock' = clock,
    }
  }

  action dispute_vote = {
    nondet cid = candidates.keys().oneOf()
    val c = candidates.get(cid)
    val eligible = VALIDATORS.exclude(c.dispute_votes_for).exclude(c.dispute_votes_against)
    all {
      c.status == Disputed,
      eligible.size() > 0,
      nondet v = eligible.oneOf(),
      val vote_for = votes_valid(v, c.validity),
      val new_for = if (vote_for) c.dispute_votes_for.union(Set(v)) else c.dispute_votes_for,
      val new_against = if (not(vote_for)) c.dispute_votes_against.union(Set(v)) else c.dispute_votes_against,
      candidates' = candidates.put(cid, { ...c,
        dispute_votes_for: new_for,
        dispute_votes_against: new_against,
      }),
      backing_groups' = backing_groups,
      next_candidate_id' = next_candidate_id,
      slashed' = slashed,
      clock' = clock,
    }
  }

  action resolve_dispute = {
    nondet cid = candidates.keys().oneOf()
    val c = candidates.get(cid)
    all {
      c.status == Disputed,
      (c.dispute_votes_for.size() >= DISPUTE_THRESHOLD or c.dispute_votes_against.size() >= DISPUTE_THRESHOLD),
      if (c.dispute_votes_for.size() >= DISPUTE_THRESHOLD) 
        all {
          candidates' = candidates.put(cid, { ...c, status: Finalized }),
          slashed' = slashed.union(c.dispute_votes_against)
        }
      else
        all {
          candidates' = candidates.put(cid, { ...c, status: Rejected }),
          slashed' = slashed.union(c.dispute_votes_for)
        },
      backing_groups' = backing_groups,
      next_candidate_id' = next_candidate_id,
      clock' = clock,
    }
  }

  action step = any {
    tick,
    submit_candidate,
    backing_vote,
    include_candidate,
    attest_availability,
    assign_approval_tranche,
    approval_vote,
    escalate_tranche,
    resolve_approved,
    dispute_vote,
    resolve_dispute,
  }

  // ==========================================================================
  // INVARIANTS & TEMPORAL PROPERTIES
  // ==========================================================================

  val safety = candidates.keys().forall(id =>
    candidates.get(id).status == Finalized implies candidates.get(id).validity == Valid
  )

  val accountability = candidates.keys().forall(id =>
    candidates.get(id).status == Rejected implies slashed.intersect(MALICIOUS).size() > 0
  )

  // Temporal: eventually every candidate is terminal
  temporal val termination = eventually(candidates.keys().size() > 0 and candidates.keys().forall(id => is_terminal(candidates.get(id).status)))

  // Temporal: if a valid candidate is available, it eventually gets finalized (assuming no infinite no-shows)
  temporal val liveness = candidates.keys().forall(id =>
    (candidates.get(id).validity == Valid and candidates.get(id).status == Available)
      implies eventually(candidates.get(id).status == Finalized)
  )
}
