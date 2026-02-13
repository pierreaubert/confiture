module test_priority_scoring {
  import confiture.* from "../confiture"
  
  run test_priority_scoring = {
    init
    .then(deploy_service("alice", "priority_service", MIN_SERVICE_BALANCE, "r", "a", "m"))
    .expect(and {
      state_basic.services.keys().size() == 1,
      system_invariant
    })
  }
}