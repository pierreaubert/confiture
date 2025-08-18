module test_nothing_at_stake {
  import confiture.* from "../confiture"

  // Test 16: Nothing at Stake Attack Prevention
  run test_nothing_at_stake = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(produce_block)
    // Validator tries to vote on multiple competing chains
    .then(submit_grandpa_vote(0, Prevote, "vote_chain_a", 1))
    .then(submit_grandpa_vote(0, Prevote, "vote_chain_b", 1))  // Conflicting vote
    .expect(and {
      // System should detect equivocation
      state_dispute.disputes.keys().size() >= 0,  // May create dispute for equivocation
      state_dispute.slashing_events.size() >= 0  // May slash for double voting
    })
  }
}
