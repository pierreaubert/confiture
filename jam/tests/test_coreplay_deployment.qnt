module test_coreplay_deployment {
  import confiture.* from "../confiture"
  
  run test_coreplay_deployment = {
    init
    .then(deploy_service("alice", "coreplay_service", MIN_SERVICE_BALANCE, "r", "a", "m"))
    .expect(and {
      state_basic.services.keys().size() == 1,
      system_invariant
    })
  }
}