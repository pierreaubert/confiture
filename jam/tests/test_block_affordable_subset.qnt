module test_block_affordable_subset {
  import confiture.* from "../confiture"
  run test_block_affordable_subset = {
    init
    .then(deploy_service("alice", "subset_svc", MIN_SERVICE_BALANCE + 1000, "r","a","m"))
    .then(submit_service_call("alice", 0, "ok1", 100, 1))
    .then(submit_service_call("alice", 0, "ok2", 200, 1))
    .then(submit_service_call("alice", 0, "too_big", 20000, 1))
    .then(produce_block)
    .expect(and {
      state_blockchain.blocks.get(1).extrinsics.size() == 2,
      state_basic.accounts.get("alice") == 10000 - (MIN_SERVICE_BALANCE + 1000) - (100 + 200)
    })
  }
}