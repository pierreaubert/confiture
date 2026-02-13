module test_5val_3core_validator_assignment {
  import confiture.* from "../confiture"
  
  run test_5val_3core_basic = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator4", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator5", MIN_VALIDATOR_STAKE))
    .then(deploy_service("alice", "test_service", MIN_SERVICE_BALANCE, "r", "a", "m"))
    .expect(and {
      state_safrole.validator_count == 5,
      state_basic.services.keys().size() == 1,
      system_invariant
    })
  }
}