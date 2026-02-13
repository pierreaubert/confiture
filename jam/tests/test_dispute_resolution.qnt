module test_dispute_resolution {
  import confiture.* from "../confiture"

  // Test 6: Dispute Resolution System
  run test_dispute_resolution = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(deploy_service("alice", "test_service", MIN_SERVICE_BALANCE, "r", "a", "m"))
    .expect(and {
      state_dispute.disputes.keys().size() == 1,
      state_dispute.disputes.get(1).status == DisputeOpen,
      state_dispute.disputes.get(1).target_validator == "validator2"
    })
  }
}
