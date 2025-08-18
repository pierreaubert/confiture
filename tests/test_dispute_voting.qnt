module test_dispute_voting {
  import confiture.* from "../confiture"
  
  run test_dispute_voting = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .expect(and {
      state_safrole.validator_count == 2,
      system_invariant
    })
  }
}