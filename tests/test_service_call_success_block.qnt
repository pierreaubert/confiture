module test_service_call_success_block {
  import confiture.* from "../confiture"
  run test_service_call_success_block = {
    init
    .then(deploy_service("alice", "svc_hash", 2000, "r","a","m"))
    .then(submit_service_call("alice", 0, "methodX", 100, 2)) // cost 200
    .then(produce_block)
    .expect(and {
      blocks.get(1).extrinsics.size() == 1,
      accounts.get("alice") == 10000 - 2000 - 200
    })
  }
}