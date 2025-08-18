module test_service_call_unaffordable_filtered {
  import confiture.* from "../confiture"
  run test_service_call_unaffordable_filtered = {
    init
    .then(deploy_service("alice", "svc_hash2", 1500, "r","a","m"))
    .then(submit_service_call("alice", 0, "expensiveCall", 9000, 5)) // cost 45000
    .then(produce_block)
    .expect(and {
      blocks.get(1).extrinsics.size() == 0,
      accounts.get("alice") == 10000 - 1500
    })
  }
}