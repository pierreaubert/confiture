module test_basic_init {
  import confiture.* from "../confiture"

  // Test 1: Basic initialization
  run test_basic_init = {
    init
    .expect(and {
      state_basic.services.keys().size() == 0,
      state_safrole.validator_count == 0,
      state_safrole.current_slot == 0
    })
  }
}
