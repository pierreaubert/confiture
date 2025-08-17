module test_dispute_resolution {
  import confiture.* from "../confiture"

  // Test 6: Dispute Resolution System
  run test_dispute_resolution = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(initiate_dispute("validator1", "validator2", InvalidWorkPackage, "evidence_data"))
    .expect(and {
      disputes.keys().size() == 1,
      disputes.get(1).status == DisputeOpen,
      disputes.get(1).target_validator == "validator2"
    })
  }
}
