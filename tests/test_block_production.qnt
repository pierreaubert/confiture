module test_block_production {
  import confiture.* from "../confiture"

  // Test: Service call converted to extrinsic and gas deducted on block production
  run test_service_call_and_block = {
    init
    .then(deploy_service("alice", "h", 1500, "r", "a", "m"))
    .then(submit_service_call("alice", 0, "methodX", 100, 2)) // cost 200
    .then(produce_block)
    .expect(and {
      current_block == 1,
      blocks.keys().contains(1),
      // Extrinsics root stubbed, but at least one extrinsic should have been added
      blocks.get(1).extrinsics.size() == 1,
      accounts.get("alice") == 10000 - 1500 - 200
    })
  }

  // Test: Block production with unaffordable call (gas too high) leaves call un-executed
  run test_unaffordable_call_filtered = {
    init
    .then(deploy_service("alice", "h", 1500, "r", "a", "m"))
    // Gas price * limit large so it's unaffordable (exceeds remaining balance)
    .then(submit_service_call("alice", 0, "expensive", 9000, 5)) // cost 45000
    .then(produce_block)
    .expect(and {
      current_block == 1,
      // Call should not have executed nor deducted
      accounts.get("alice") == 10000 - 1500,
      blocks.get(1).extrinsics.size() == 0
    })
  }
}