module test_grandpa_finality {
  import confiture.* from "../confiture"

  // Test 13: GRANDPA Finality Gadget
  run test_grandpa_finality = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(submit_grandpa_vote(0, Prevote, "block_hash", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash", 1))
    .then(finalize_block("block_hash", 1))
    .expect(and {
      state_grandpa.finalized_blocks.contains(1),
      state_grandpa.grandpa_round >= 1,
      state_pvm.finality_justifications.keys().contains(1)
    })
  }
}
