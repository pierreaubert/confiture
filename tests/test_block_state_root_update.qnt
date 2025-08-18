module test_block_state_root_update {
  import confiture.* from "../confiture"
  run test_block_state_root_update = {
    init
    .then(produce_block)
    .expect(jam_state_root == "state_block_updated")
  }
}