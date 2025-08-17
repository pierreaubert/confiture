module test_basic_init {
  import confiture.* from "../confiture"

  // Test 1: Basic initialization
  run test_basic_init = {
    init
    .expect(and {
      services.keys().size() == 0,
      validator_count == 0,
      current_slot == 0
    })
  }
}
