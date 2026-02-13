module test_deploy_service_success {
  import confiture.* from "../confiture"
  run test_deploy_service_success = {
    init
    .then(deploy_service("alice", "code_hash_v1", MIN_SERVICE_BALANCE + 500, "refine_fn", "acc_fn", "on_msg_fn"))
    .expect(and {
      state_basic.services.keys().size() == 1,
      state_basic.services.get(0).owner == "alice",
      state_basic.services.get(0).balance == MIN_SERVICE_BALANCE + 500,
      state_basic.accounts.get("alice") == 10000 - (MIN_SERVICE_BALANCE + 500),
      system_invariant
    })
  }
}