module test_grandpa_justification {
  import confiture.* from "../confiture"
  
  run test_grandpa_justification = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .expect(and {
      state_basic.current_block == 1,
      state_grandpa.finalized_blocks.contains(0),
      system_invariant
    })
  }
}