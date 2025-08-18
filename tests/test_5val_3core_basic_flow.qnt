module test_5val_3core_basic_flow {
  import confiture.* from "../confiture"

  // Custom configuration with 5 validators and 3 cores
  pure val TEST_VALIDATORS = Set("val1", "val2", "val3", "val4", "val5")
  pure val TEST_CORES = 3
  pure val TEST_CORE_INDICES = 0.to(TEST_CORES - 1)

  // Custom init action for 5 validators and 3 cores
  action init_5val_3core = all {
    current_block' = 0,
    services' = Map(),
    accounts' = Map("alice" -> 10000, "bob" -> 10000, "charlie" -> 5000),
    pending_calls' = Set(),
    next_service_id' = 1,

    // Initialize only 3 cores
    cores' = TEST_CORE_INDICES.mapBy(i => {
      index: i,
      state: Available,
      current_package: 0,
      validator_set: Set(),
      time_allocated: 0
    }),

    // Initialize JAM-specific state
    work_packages' = Map(),
    work_results' = Map(),
    pending_work_packages' = Set(),
    next_package_id' = 1,
    next_work_item_id' = 1,

    // Initialize JAM state
    jam_state_root' = "genesis_state",
    entropy_pool' = "initial_entropy",
    validator_assignments' = TEST_CORE_INDICES.mapBy(_ => Set()),

    // Initialize blockchain state
    blocks' = Map(0 -> {
      header: {
        parent_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
        block_number: 0,
        state_root: "genesis_state",
        extrinsics_root: "empty_extrinsics",
        entropy_pool_root: "initial_entropy",
        timestamp: 0,
        epoch: 0,
        winning_tickets: Set(),
        offenders_markers: Set(),
        author_index: 0,
        seal: "genesis_seal"
      },
      extrinsics: Set(),
      guarantees: Set(),
      assurances: Set(),
      preimages: Set(),
      availability: Set()
    }),
    chain_head' = 0,
    current_epoch' = 0,
    pending_extrinsics' = Set(),
    next_extrinsic_id' = 1,

    // Initialize 5 validators
    validators' = TEST_VALIDATORS.fold(Map(), (acc, val_name) => {
      val idx = TEST_VALIDATORS.fold(0, (count, v) => if (v == val_name) count else count + 1)
      acc.put(idx, {
        index: idx,
        public_key: val_name,
        state: ValidatorActive,
        stake: MIN_VALIDATOR_STAKE,
        core_assignments: Set(),
        last_block_authored: 0
      })
    }),
    validator_count' = TEST_VALIDATORS.size(),
    tickets' = Map(),
    pending_tickets' = Set(),
    current_slot' = 0,
    entropy_accumulator' = "initial_entropy",

    // Initialize GRANDPA finality state
    finalized_blocks' = Set(0),
    grandpa_round' = 0,
    pending_votes' = Set(),
    finality_justifications' = Map(),

    // Initialize PVM execution state
    pvm_programs' = Map(),
    pvm_contexts' = Map(),
    pvm_gas_used' = 0,

    // Initialize Data Availability Layer state
    data_blobs' = Map(),
    data_segments' = Map(),
    next_blob_id' = 1,
    availability_threshold' = 2,

    // Initialize Dispute Resolution System
    disputes' = Map(),
    next_dispute_id' = 1,
    slashing_events' = Set(),

    // Initialize Advanced Scheduling state
    scheduled_packages' = Set(),
    scheduling_policy' = PriorityBased,

    // Initialize CoreChains compatibility state
    parachains' = Map(),
    xcmp_messages' = Set(),
    next_xcmp_message_id' = 1
  }

  // Helper function to get available cores in 3-core setup
  pure def available_cores_3core(core_map: int -> Core): Set[int] =
    TEST_CORE_INDICES.filter(i => core_map.get(i).state == Available)

  // Helper literal work item set
  val wi_set = Set({
    id: 0,
    service_id: 0,
    payload: "payload0",
    gas_limit: 5000,
    status: WorkPending,
    refine_output: "",
    accumulate_input: ""
  })

  // Test: Basic work package flow with 3 cores
  run test_basic_flow_3cores = {
    init_5val_3core
    .then(deploy_service("alice", "hash_code", 2000, "refine", "acc", "on_msg"))
    .then(submit_work_package(0, wi_set, "auth_sig"))
    .then(refine_work_package(0))
    .then(accumulate_work_results(Set(0)))
    .expect(and {
      work_results.keys().contains(0),
      work_results.get(0).success,
      work_packages.keys().contains(0),
      jam_state_root == "state_accumulated",
      cores.get(work_results.get(0).core_index).state == Available,
      // Verify we're using only 3 cores
      cores.keys().size() == TEST_CORES,
      cores.keys().forall(idx => idx < TEST_CORES)
    })
  }

  // Test: All 3 cores can be occupied simultaneously
  run test_all_cores_occupied = {
    init_5val_3core
    .then(deploy_service("alice", "hash_code1", 2000, "refine", "acc", "on_msg"))
    .then(deploy_service("bob", "hash_code2", 2000, "refine", "acc", "on_msg"))
    .then(deploy_service("charlie", "hash_code3", 2000, "refine", "acc", "on_msg"))
    .then(submit_work_package(0, wi_set, "auth1"))
    .then(submit_work_package(1, wi_set, "auth2"))
    .then(submit_work_package(2, wi_set, "auth3"))
    .expect(and {
      // All 3 cores should be occupied
      cores.get(0).state == Occupied,
      cores.get(1).state == Occupied,
      cores.get(2).state == Occupied,
      // 3 pending work packages
      pending_work_packages.size() == 3
    })
  }

  // Test: Cannot submit work package when all cores are occupied
  run test_no_available_cores = {
    init_5val_3core
    .then(deploy_service("alice", "hash_code1", 2000, "refine", "acc", "on_msg"))
    .then(deploy_service("bob", "hash_code2", 2000, "refine", "acc", "on_msg"))
    .then(submit_work_package(0, wi_set, "auth1"))
    .then(submit_work_package(1, wi_set, "auth2"))
    .then(submit_work_package(0, wi_set, "auth3"))
    .then(submit_work_package(1, wi_set, "auth4")) // This should fail - no cores available
    .expect(and {
      // Only 3 cores, all occupied
      cores.get(0).state == Occupied,
      cores.get(1).state == Occupied,
      cores.get(2).state == Occupied,
      // Only 3 work packages should be submitted
      pending_work_packages.size() == 3
    })
  }

  // Test: Validator count verification
  run test_validator_count = {
    init_5val_3core
    .expect(and {
      validator_count == 5,
      validators.keys().size() == 5,
      validators.keys().forall(idx => validators.get(idx).state == ValidatorActive),
      TEST_VALIDATORS.forall(val_name => 
        validators.keys().exists(idx => validators.get(idx).public_key == val_name)
      )
    })
  }
}
