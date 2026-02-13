module test_deploy_exact_min_balance {
  import confiture.* from "../confiture"
  run test_deploy_exact_min_balance = {
    init
    .then(deploy_service("alice", "hash_min", MIN_SERVICE_BALANCE, "r","a","m"))
    .expect(and {
      state_basic.services.keys().size() == 1,
      state_basic.services.get(0).balance == MIN_SERVICE_BALANCE
    })
  }
}