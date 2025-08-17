module test_attack_simulation {
  import confiture.* from "../confiture"

  // Test 14: Attack Simulation - Double Spending
  run test_attack_simulation = {
    init
    .then(register_validator("attacker", MIN_VALIDATOR_STAKE))
    .then(register_validator("honest", MIN_VALIDATOR_STAKE))
    .then(deploy_service("alice", "service_code", 1000, "refine", "accumulate", "message"))
    .then(submit_service_call("alice", 1, "transfer", 1000, 1))
    .then(submit_service_call("alice", 1, "transfer", 1000, 1))  // Double spend attempt
    .expect(and {
      pending_calls.size() == 2,
      // System should detect conflicting transactions
      true  // Placeholder for actual double-spend detection logic
    })
  }
}
