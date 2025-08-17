module test_coreplay_deployment {
  import confiture.* from "../confiture"

  // Test 4: CorePlay Actor Deployment
  run test_coreplay_deployment = {
    init
    .then(deploy_coreplay_actor("alice", "contract_code", "initial_state"))
    .expect(and {
      services.keys().size() == 1,
      services.get(1).state == ServiceActive,
      services.get(1).owner == "alice"
    })
  }
}
