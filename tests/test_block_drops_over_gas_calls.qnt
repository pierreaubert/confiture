module test_block_drops_over_gas_calls {
  import confiture.* from "../confiture"
  run test_block_drops_over_gas_calls = {
    init
    .then(deploy_service("alice", "gas_drop_svc", MIN_SERVICE_BALANCE, "r","a","m"))
    .then(submit_service_call("alice", 0, "c1", MAX_GAS_PER_BLOCK / 2 + 1, 1))
    .then(submit_service_call("alice", 0, "c2", MAX_GAS_PER_BLOCK / 2 + 1, 1))
    .then(produce_block)
    .expect(and {
      state_blockchain.blocks.get(1).extrinsics.size() == 0,
      state_basic.accounts.get("alice") == 10000 - MIN_SERVICE_BALANCE
    })
  }
}