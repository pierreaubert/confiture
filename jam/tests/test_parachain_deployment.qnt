module test_parachain_deployment {
  import confiture.* from "../confiture"

  // Test 10: CoreChains Parachain Deployment (simplified test)
  run test_parachain_deployment = {
    init
    .then(deploy_service("alice", "parachain_service", MIN_SERVICE_BALANCE + 1000, "r", "a", "m"))
    .expect(and {
      state_corechains.parachains.keys().size() == 0,  // No state_corechains.parachains deployed yet
      state_basic.services.keys().size() == 1  // Service deployed
    })
  }
}
