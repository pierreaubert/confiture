module test_validator_behavior {
  import confiture.* from "../confiture"

  // Test 12: Validator Behavior and Rewards
  run test_validator_behavior = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(distribute_rewards(0, BLOCK_REWARD))
    .expect(and {
      validators.keys().size() == 1,
      validators.get(0).stake >= MIN_VALIDATOR_STAKE,
      blocks.keys().size() == 1
    })
  }
}
