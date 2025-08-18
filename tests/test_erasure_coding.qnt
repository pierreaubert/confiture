module test_erasure_coding {
  import confiture.* from "../confiture"

  // Test 5: Data blob erasure coding
  run test_erasure_coding = {
    init
    .then(deploy_service("alice", "test_service", MIN_SERVICE_BALANCE, "r", "a", "m"))
    .expect(and {
      state_data_availability.data_segments.keys().contains(1),
      state_data_availability.data_segments.get(1).size() == 4
    })
  }
}
