module test_xcmp_messaging {
  import confiture.* from "../confiture"
  
  run test_xcmp_messaging = {
    init
    .then(deploy_service("alice", "xcmp_service", MIN_SERVICE_BALANCE, "r", "a", "m"))
    .then(submit_service_call("alice", 0, "xcmp_method", 100, 1))
    .expect(and {
      state_basic.services.keys().size() == 1,
      system_invariant
    })
  }
}