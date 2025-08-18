module test_grandpa_voting {
  import confiture.* from "../confiture"
  
  run test_grandpa_voting = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .expect(and {
      state_grandpa.finalized_blocks.size() >= 1,
      system_invariant
    })
  }
}