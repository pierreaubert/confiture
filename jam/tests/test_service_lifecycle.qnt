module test_service_lifecycle {
  import confiture.* from "../confiture"

  // Test: Successful service deployment deducts balance and registers service
  run test_deploy_service_success = {
    init
    .then(deploy_service("alice", "hash_code_v1", 2000, "refine_fn", "acc_fn", "on_msg_fn"))
    .expect(and {
      state_basic.services.keys().size() == 1,
      state_basic.services.get(0).owner == "alice",
      state_basic.services.get(0).state == ServiceActive,
      state_basic.services.get(0).balance == 2000,
      state_basic.accounts.get("alice") == 10000 - 2000
    })
  }

  // Test: Deployment fails when below MIN_SERVICE_BALANCE (should not change registry)
  run test_deploy_service_too_low_balance = {
    init
    .then(deploy_service("alice", "hash_code_v2", 500, "r", "a", "m"))
    .expect(and {
      // Action should fail its guard; no service added
      state_basic.services.keys().size() == 0
    })
  }

  // Test: Deployment fails if owner lacks sufficient funds
  run test_deploy_service_insufficient_funds = {
    init
    // Try to deploy with more than alice has
    .then(deploy_service("alice", "hash_big", 200000, "r", "a", "m"))
    .expect(state_basic.services.keys().size() == 0)
  }
}