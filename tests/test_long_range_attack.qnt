module test_long_range_attack {
  import confiture.* from "../confiture"
  
  run test_long_range_attack = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .expect(and {
      state_safrole.validator_count == 2,
      state_basic.current_block == 1,
      system_invariant
    })
  }
}