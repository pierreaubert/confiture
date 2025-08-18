module test_data_availability {
  import confiture.* from "../confiture"
  
  run test_data_availability = {
    init
    .then(deploy_service("alice", "data_service", MIN_SERVICE_BALANCE, "r", "a", "m"))
    .expect(and {
      state_data_availability.data_blobs.keys().size() == 0,
      state_basic.services.keys().size() == 1,
      system_invariant
    })
  }
}