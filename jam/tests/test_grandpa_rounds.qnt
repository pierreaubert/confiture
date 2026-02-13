module test_grandpa_rounds {
  import confiture.* from "../confiture"
  
  run test_grandpa_rounds = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .expect(and {
      state_grandpa.grandpa_round >= 0,
      state_basic.current_block == 1,
      system_invariant
    })
  }
}