//                                                                          -*- quint -*-

module elves_v2 {
  // ==========================================================================
  // TYPES
  // ==========================================================================
  type CandidateStatus = Seconded | Backable | PendingAvailability | Available
                       | ApprovalPending | Approved | Disputed | Finalized | Rejected

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
    dispute_votes_for: Set[int],
    dispute_votes_against: Set[int]
  }

  // ==========================================================================
  // CONSTANTS
  // ==========================================================================
  pure val VALIDATORS: Set[int] = 0.to(9)
  pure val HONEST: Set[int] = 0.to(6)
  pure val MALICIOUS: Set[int] = Set(7, 8, 9)
  pure val CORES: Set[int] = Set(0, 1, 2)
  pure val BACKING_THRESHOLD: int = 2
  pure val AVAILABILITY_THRESHOLD: int = 7
  pure val APPROVAL_TRANCHES: int = 2
  pure val CHECKERS_PER_TRANCHE: int = 2
  pure val DISPUTE_THRESHOLD: int = 7
  pure val MAX_CANDIDATES: int = 6

  // ==========================================================================
  // HELPERS
  // ==========================================================================
  pure def is_honest(v: int): bool = HONEST.contains(v)

  pure def is_terminal(status: CandidateStatus): bool =
    status == Finalized or status == Rejected

  // Ground truth vote: honest vote truthfully, malicious always lie
  pure def votes_valid(v: int, validity: CandidateValidity): bool =
    if (is_honest(v)) validity == Valid
    else validity == Invalid

  // Collect all validators assigned across all approval tranches
  pure def all_assigned_checkers(c: Candidate): Set[int] =
    VALIDATORS.filter(v =>
      c.approval_assignments.keys().exists(t =>
        c.approval_assignments.get(t).contains(v)
      )
    )

  // Check if a tranche is fully resolved (all checkers voted or no-show)
  pure def tranche_fully_resolved(c: Candidate, t: int): bool =
    if (not(c.approval_assignments.keys().contains(t))) false
    else c.approval_assignments.get(t).forall(v =>
      c.approval_votes_for.contains(v) or
      c.approval_votes_against.contains(v) or
      c.no_shows.contains(v)
    )

  // Check if a tranche has any no-shows
  pure def tranche_has_noshows(c: Candidate, t: int): bool =
    if (not(c.approval_assignments.keys().contains(t))) false
    else c.approval_assignments.get(t).intersect(c.no_shows).size() > 0

  // ==========================================================================
  // STATE VARIABLES
  // ==========================================================================
  var candidates: int -> Candidate
  var backing_groups: int -> Set[int]
  var next_candidate_id: int
  var slashed: Set[int]

  // ==========================================================================
  // INITIALIZATION
  // ==========================================================================
  action init = all {
    candidates' = Map(),
    backing_groups' = Map()
      .put(0, Set(0, 1, 2))
      .put(1, Set(3, 4, 5))
      .put(2, Set(6, 7, 8)),
    next_candidate_id' = 0,
    slashed' = Set(),
  }

  // ==========================================================================
  // ACTIONS
  // ==========================================================================

  // Helper: always-disabled action with correct effect signature for if-else branches
  action disabled = all {
    false,
    candidates' = candidates,
    next_candidate_id' = next_candidate_id,
    backing_groups' = backing_groups,
    slashed' = slashed,
  }

  // 1. Submit a new candidate on a free core
  action submit_candidate = {
    nondet core = oneOf(CORES)
    nondet validity = oneOf(Set(Valid, Invalid))
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
        dispute_votes_for: Set(),
        dispute_votes_against: Set(),
      }),
      next_candidate_id' = next_candidate_id + 1,
      backing_groups' = backing_groups,
      slashed' = slashed,
    }
  }

  // 2. Backing vote from an assigned group member
  action backing_vote = {
    val eligible_cands = candidates.keys().filter(id =>
      candidates.get(id).status == Seconded
    )
    if (eligible_cands.size() > 0) {
      nondet cid = oneOf(eligible_cands)
      val c = candidates.get(cid)
      val eligible_backers = backing_groups.get(c.core)
        .exclude(c.backer_votes_for)
        .exclude(c.backer_votes_against)
      if (eligible_backers.size() > 0) {
        nondet v = oneOf(eligible_backers)
        val vote_for = votes_valid(v, c.validity)
        val new_for = if (vote_for) c.backer_votes_for.union(Set(v))
                      else c.backer_votes_for
        val new_against = if (not(vote_for)) c.backer_votes_against.union(Set(v))
                          else c.backer_votes_against
        val new_status = if (new_for.size() >= BACKING_THRESHOLD) Backable
                         else Seconded
        all {
          candidates' = candidates.put(cid, { ...c,
            backer_votes_for: new_for,
            backer_votes_against: new_against,
            status: new_status,
          }),
          next_candidate_id' = next_candidate_id,
          backing_groups' = backing_groups,
          slashed' = slashed,
        }
      } else disabled
    } else disabled
  }

  // 3. Include a backable candidate into pending availability
  action include_candidate = {
    val eligible = candidates.keys().filter(id =>
      candidates.get(id).status == Backable
    )
    if (eligible.size() > 0) {
      nondet cid = oneOf(eligible)
      val c = candidates.get(cid)
      all {
        candidates' = candidates.put(cid, { ...c, status: PendingAvailability }),
        next_candidate_id' = next_candidate_id,
        backing_groups' = backing_groups,
        slashed' = slashed,
      }
    } else disabled
  }

  // 4. Attest data availability
  action attest_availability = {
    val eligible_cands = candidates.keys().filter(id =>
      candidates.get(id).status == PendingAvailability
    )
    if (eligible_cands.size() > 0) {
      nondet cid = oneOf(eligible_cands)
      val c = candidates.get(cid)
      val eligible_attesters = VALIDATORS.exclude(c.availability_attestations)
      if (eligible_attesters.size() > 0) {
        nondet v = oneOf(eligible_attesters)
        val new_attestations = c.availability_attestations.union(Set(v))
        val new_status = if (new_attestations.size() >= AVAILABILITY_THRESHOLD) Available
                         else PendingAvailability
        all {
          candidates' = candidates.put(cid, { ...c,
            availability_attestations: new_attestations,
            status: new_status,
          }),
          next_candidate_id' = next_candidate_id,
          backing_groups' = backing_groups,
          slashed' = slashed,
        }
      } else disabled
    } else disabled
  }

  // 5. Assign approval checkers for the current tranche (models VRF guarantee)
  action assign_approval_tranche = {
    val eligible_cands = candidates.keys().filter(id =>
      (candidates.get(id).status == Available or
       candidates.get(id).status == ApprovalPending) and
      candidates.get(id).current_tranche < APPROVAL_TRANCHES and
      not(candidates.get(id).approval_assignments.keys().contains(
        candidates.get(id).current_tranche))
    )
    if (eligible_cands.size() > 0) {
      nondet cid = oneOf(eligible_cands)
      val c = candidates.get(cid)
      val tranche = c.current_tranche
      val already_assigned = all_assigned_checkers(c)
      val eligible = VALIDATORS.exclude(already_assigned)
      // At least one honest checker per tranche (models VRF statistical guarantee)
      val valid_checker_sets = eligible.powerset().filter(s =>
        s.size() == CHECKERS_PER_TRANCHE and s.intersect(HONEST).size() > 0
      )
      if (valid_checker_sets.size() > 0) {
        nondet checkers = oneOf(valid_checker_sets)
        val new_status = if (c.status == Available) ApprovalPending else c.status
        all {
          candidates' = candidates.put(cid, { ...c,
            approval_assignments: c.approval_assignments.put(tranche, checkers),
            status: new_status,
          }),
          next_candidate_id' = next_candidate_id,
          backing_groups' = backing_groups,
          slashed' = slashed,
        }
      } else disabled
    } else disabled
  }

  // 6. Approval vote from an assigned checker
  action approval_vote = {
    val eligible_cands = candidates.keys().filter(id =>
      candidates.get(id).status == ApprovalPending
    )
    if (eligible_cands.size() > 0) {
      nondet cid = oneOf(eligible_cands)
      val c = candidates.get(cid)
      val assigned = all_assigned_checkers(c)
      val eligible_voters = assigned
        .exclude(c.approval_votes_for)
        .exclude(c.approval_votes_against)
        .exclude(c.no_shows)
      if (eligible_voters.size() > 0) {
        nondet v = oneOf(eligible_voters)
        val vote_for = votes_valid(v, c.validity)
        val new_for = if (vote_for) c.approval_votes_for.union(Set(v))
                      else c.approval_votes_for
        val new_against = if (not(vote_for)) c.approval_votes_against.union(Set(v))
                          else c.approval_votes_against
        val remaining = assigned
          .exclude(new_for)
          .exclude(new_against)
          .exclude(c.no_shows)
        val new_status = if (remaining.size() == 0 and new_against.size() == 0) Approved
                         else ApprovalPending
        // Check if this vote completed tranche resolution with no-shows → escalate
        val tranche_checkers =
          if (c.approval_assignments.keys().contains(c.current_tranche))
            c.approval_assignments.get(c.current_tranche)
          else Set()
        val tranche_resolved_after = tranche_checkers.forall(checker =>
          new_for.contains(checker) or new_against.contains(checker) or c.no_shows.contains(checker)
        )
        val tranche_noshows = tranche_checkers.intersect(c.no_shows).size() > 0
        val new_tranche =
          if (new_status == ApprovalPending and tranche_resolved_after and tranche_noshows
              and c.current_tranche + 1 < APPROVAL_TRANCHES)
            c.current_tranche + 1
          else c.current_tranche
        all {
          candidates' = candidates.put(cid, { ...c,
            approval_votes_for: new_for,
            approval_votes_against: new_against,
            status: new_status,
            current_tranche: new_tranche,
          }),
          next_candidate_id' = next_candidate_id,
          backing_groups' = backing_groups,
          slashed' = slashed,
        }
      } else disabled
    } else disabled
  }

  // 7. Detect no-show of an assigned checker (only malicious validators can no-show)
  action detect_no_show = {
    val eligible_cands = candidates.keys().filter(id =>
      candidates.get(id).status == ApprovalPending
    )
    if (eligible_cands.size() > 0) {
      nondet cid = oneOf(eligible_cands)
      val c = candidates.get(cid)
      val tranche_checkers =
        if (c.approval_assignments.keys().contains(c.current_tranche))
          c.approval_assignments.get(c.current_tranche)
        else Set()
      val no_show_eligible = tranche_checkers
        .exclude(c.approval_votes_for)
        .exclude(c.approval_votes_against)
        .exclude(c.no_shows)
        .intersect(MALICIOUS)
      if (no_show_eligible.size() > 0) {
        nondet v = oneOf(no_show_eligible)
        val new_no_shows = c.no_shows.union(Set(v))
        val tranche_resolved = tranche_checkers.forall(checker =>
          c.approval_votes_for.contains(checker) or
          c.approval_votes_against.contains(checker) or
          new_no_shows.contains(checker)
        )
        val has_no_shows = tranche_checkers.intersect(new_no_shows).size() > 0
        val new_tranche =
          if (tranche_resolved and has_no_shows and c.current_tranche + 1 < APPROVAL_TRANCHES)
            c.current_tranche + 1
          else c.current_tranche
        all {
          candidates' = candidates.put(cid, { ...c,
            no_shows: new_no_shows,
            current_tranche: new_tranche,
          }),
          next_candidate_id' = next_candidate_id,
          backing_groups' = backing_groups,
          slashed' = slashed,
        }
      } else disabled
    } else disabled
  }

  // 8. Finalize an approved candidate
  action finalize_approval = {
    val eligible = candidates.keys().filter(id =>
      candidates.get(id).status == Approved
    )
    if (eligible.size() > 0) {
      nondet cid = oneOf(eligible)
      val c = candidates.get(cid)
      all {
        candidates' = candidates.put(cid, { ...c, status: Finalized }),
        next_candidate_id' = next_candidate_id,
        backing_groups' = backing_groups,
        slashed' = slashed,
      }
    } else disabled
  }

  // 9. Initiate dispute when approval votes against exist
  action initiate_dispute = {
    val eligible = candidates.keys().filter(id =>
      candidates.get(id).status == ApprovalPending and
      candidates.get(id).approval_votes_against.size() > 0
    )
    if (eligible.size() > 0) {
      nondet cid = oneOf(eligible)
      val c = candidates.get(cid)
      all {
        candidates' = candidates.put(cid, { ...c, status: Disputed }),
        next_candidate_id' = next_candidate_id,
        backing_groups' = backing_groups,
        slashed' = slashed,
      }
    } else disabled
  }

  // 10. Dispute vote from any validator
  action dispute_vote = {
    val eligible_cands = candidates.keys().filter(id =>
      candidates.get(id).status == Disputed
    )
    if (eligible_cands.size() > 0) {
      nondet cid = oneOf(eligible_cands)
      val c = candidates.get(cid)
      val eligible_voters = VALIDATORS
        .exclude(c.dispute_votes_for)
        .exclude(c.dispute_votes_against)
      if (eligible_voters.size() > 0) {
        nondet v = oneOf(eligible_voters)
        val vote_for = votes_valid(v, c.validity)
        val new_for = if (vote_for) c.dispute_votes_for.union(Set(v))
                      else c.dispute_votes_for
        val new_against = if (not(vote_for)) c.dispute_votes_against.union(Set(v))
                          else c.dispute_votes_against
        all {
          candidates' = candidates.put(cid, { ...c,
            dispute_votes_for: new_for,
            dispute_votes_against: new_against,
          }),
          next_candidate_id' = next_candidate_id,
          backing_groups' = backing_groups,
          slashed' = slashed,
        }
      } else disabled
    } else disabled
  }

  // 11. Resolve dispute when supermajority reached
  action resolve_dispute = {
    val eligible = candidates.keys().filter(id =>
      candidates.get(id).status == Disputed and (
        candidates.get(id).dispute_votes_for.size() >= DISPUTE_THRESHOLD or
        candidates.get(id).dispute_votes_against.size() >= DISPUTE_THRESHOLD
      )
    )
    if (eligible.size() > 0) {
      nondet cid = oneOf(eligible)
      val c = candidates.get(cid)
      if (c.dispute_votes_for.size() >= DISPUTE_THRESHOLD) {
        // Supermajority says valid → Finalized; slash those who voted against
        all {
          candidates' = candidates.put(cid, { ...c, status: Finalized }),
          slashed' = slashed.union(c.dispute_votes_against),
          next_candidate_id' = next_candidate_id,
          backing_groups' = backing_groups,
        }
      } else {
        // Supermajority says invalid → Rejected; slash those who voted for
        all {
          candidates' = candidates.put(cid, { ...c, status: Rejected }),
          slashed' = slashed.union(c.dispute_votes_for),
          next_candidate_id' = next_candidate_id,
          backing_groups' = backing_groups,
        }
      }
    } else disabled
  }

  // 12. Stuttering step when all candidates are terminal
  action idle = all {
    candidates.keys().size() > 0,
    candidates.keys().forall(id => is_terminal(candidates.get(id).status)),
    candidates' = candidates,
    next_candidate_id' = next_candidate_id,
    backing_groups' = backing_groups,
    slashed' = slashed,
  }

  // ==========================================================================
  // STEP
  // ==========================================================================
  action step = any {
    submit_candidate,
    backing_vote,
    include_candidate,
    attest_availability,
    assign_approval_tranche,
    approval_vote,
    detect_no_show,
    finalize_approval,
    initiate_dispute,
    dispute_vote,
    resolve_dispute,
    idle,
  }

  // ==========================================================================
  // INVARIANTS
  // ==========================================================================

  // 1. Safety: No invalid candidate is ever finalized
  val no_invalid_finalization_inv =
    candidates.keys().forall(id =>
      candidates.get(id).status == Finalized implies
        candidates.get(id).validity == Valid
    )

  // 2. Liveness: A valid candidate is never rejected
  val no_valid_rejection_inv =
    candidates.keys().forall(id =>
      candidates.get(id).status == Rejected implies
        candidates.get(id).validity == Invalid
    )

  // 3. Accountability: Rejected candidates imply at least one malicious validator slashed
  val malicious_slashed_inv =
    candidates.keys().forall(id =>
      candidates.get(id).status == Rejected implies
        slashed.intersect(MALICIOUS).size() > 0
    )

  // 4. Integrity: Backing votes only come from the assigned backing group
  val backing_group_integrity_inv =
    candidates.keys().forall(id =>
      candidates.get(id).backer_votes_for
        .union(candidates.get(id).backer_votes_against)
        .forall(v => backing_groups.get(candidates.get(id).core).contains(v))
    )

  // 5. Available+ candidates have sufficient availability attestations
  val availability_threshold_inv =
    candidates.keys().forall(id =>
      (not(candidates.get(id).status == Seconded) and
       not(candidates.get(id).status == Backable) and
       not(candidates.get(id).status == PendingAvailability))
        implies
          candidates.get(id).availability_attestations.size() >= AVAILABILITY_THRESHOLD
    )

  // 6. No validator appears in both for and against sets
  val no_double_voting_inv =
    candidates.keys().forall(id =>
      candidates.get(id).backer_votes_for
        .intersect(candidates.get(id).backer_votes_against).size() == 0 and
      candidates.get(id).approval_votes_for
        .intersect(candidates.get(id).approval_votes_against).size() == 0 and
      candidates.get(id).dispute_votes_for
        .intersect(candidates.get(id).dispute_votes_against).size() == 0
    )

  // 7. Dispute resolution requires supermajority
  val dispute_resolution_threshold_inv =
    candidates.keys().forall(id =>
      (candidates.get(id).status == Finalized and
       candidates.get(id).dispute_votes_for.size() > 0) implies
        candidates.get(id).dispute_votes_for.size() >= DISPUTE_THRESHOLD
    ) and
    candidates.keys().forall(id =>
      candidates.get(id).status == Rejected implies
        candidates.get(id).dispute_votes_against.size() >= DISPUTE_THRESHOLD
    )

  // 8. At most one active (non-terminal) candidate per core
  val core_exclusivity_inv =
    CORES.forall(core =>
      candidates.keys().filter(id =>
        candidates.get(id).core == core and
        not(is_terminal(candidates.get(id).status))
      ).size() <= 1
    )

  // 9. Only incorrect voters get slashed
  val slashing_correctness_inv =
    slashed.forall(v =>
      candidates.keys().exists(id =>
        (candidates.get(id).dispute_votes_against.contains(v) and
         candidates.get(id).validity == Valid) or
        (candidates.get(id).dispute_votes_for.contains(v) and
         candidates.get(id).validity == Invalid)
      )
    )

  // 10. No-shows in a tranche trigger escalation to the next tranche
  //     (only applies while candidate is still ApprovalPending; if already Approved
  //     or Disputed, escalation is moot since the approval phase concluded)
  val noshow_escalation_inv =
    candidates.keys().forall(id =>
      (candidates.get(id).status == ApprovalPending and
       tranche_fully_resolved(candidates.get(id), 0) and
       tranche_has_noshows(candidates.get(id), 0))
        implies candidates.get(id).current_tranche >= 1
    )
}
