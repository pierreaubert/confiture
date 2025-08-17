module test_parachain_deployment {
  import confiture.* from "../confiture"

  // Test 10: CoreChains Parachain Deployment
  run test_parachain_deployment = {
    init
    .then(deploy_parachain(1000, "genesis_head_data", "validation_code_hash", 0, 100))
    .expect(and {
      parachains.keys().size() == 1,
      parachains.get(1000).state == Onboarding,
      services.keys().size() == 1  // Should create corresponding JAM service
    })
  }
}
