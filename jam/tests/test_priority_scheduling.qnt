module test_priority_scheduling {
  import confiture.* from "../confiture"
  
  run test_priority_scheduling = {
    init
    .then(deploy_service("alice", "scheduling_service", MIN_SERVICE_BALANCE, "r", "a", "m"))
    .expect(and {
      state_basic.services.keys().size() == 1,
      system_invariant
    })
  }
}