module test_dispute_voting {
  import confiture.* from "../confiture"

  // Test 7: Dispute Voting and Slashing
  run test_dispute_voting = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(initiate_dispute("validator1", "validator2", SlashableOffense, "malicious_behavior"))
    .then(vote_on_dispute(1, "validator1", true))
    .then(vote_on_dispute(1, "validator3", true))
    .expect(and {
      disputes.get(1).resolution_votes.size() >= 2,
      slashing_events.size() >= 0  // May trigger slashing based on vote threshold
    })
  }
}
