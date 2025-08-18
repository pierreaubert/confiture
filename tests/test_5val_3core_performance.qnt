module test_5val_3core_performance {
  import confiture.* from "../confiture"

  // Custom configuration with 5 validators and 3 cores
  pure val TEST_VALIDATORS = Set("val1", "val2", "val3", "val4", "val5")
  pure val TEST_CORES = 3
  pure val TEST_CORE_INDICES = 0.to(TEST_CORES - 1)

  // Custom init action for 5 validators and 3 cores
  action init_5val_3core = all {
    current_block' = 0,
    services' = Map(),
    accounts' = Map("alice" -> 20000, "bob" -> 20000, "charlie" -> 10000),
    pending_calls' = Set(),
    next_service_id' = 1,

    cores' = TEST_CORE_INDICES.mapBy(i => {
      index: i,
      state: Available,
      current_package: 0,
      validator_set: Set(),
      time_allocated: 0
    }),

    work_packages' = Map(),
    work_results' = Map(),
    pending_work_packages' = Set(),
    next_package_id' = 1,
    next_work_item_id' = 1,

    jam_state_root' = "genesis_state",
    entropy_pool' = "initial_entropy",
    validator_assignments' = TEST_CORE_INDICES.mapBy(_ => Set()),

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

    finalized_blocks' = Set(0),
    grandpa_round' = 0,
    pending_votes' = Set(),
    finality_justifications' = Map(),

    pvm_programs' = Map(),
    pvm_contexts' = Map(),
    pvm_gas_used' = 0,

    data_blobs' = Map(),
    data_segments' = Map(),
    next_blob_id' = 1,
    availability_threshold' = 2,

    disputes' = Map(),
    next_dispute_id' = 1,
    slashing_events' = Set(),

    scheduled_packages' = Set(),
    scheduling_policy' = PriorityBased,

    parachains' = Map(),
    xcmp_messages' = Set(),
    next_xcmp_message_id' = 1
  }

  // Helper work item sets for testing
  val wi_set_small = Set({
    id: 0,
    service_id: 0,
    payload: "small_payload",
    gas_limit: 1000,
    status: WorkPending,
    refine_output: "",
    accumulate_input: ""
  })

  val wi_set_medium = Set({
    id: 1,
    service_id: 0,
    payload: "medium_payload",
    gas_limit: 5000,
    status: WorkPending,
    refine_output: "",
    accumulate_input: ""
  })

  val wi_set_large = Set({
    id: 2,
    service_id: 0,
    payload: "large_payload",
    gas_limit: 10000,
    status: WorkPending,
    refine_output: "",
    accumulate_input: ""
  })

  // Test: Maximum throughput with 3 cores
  run test_max_throughput_3cores = {
    init_5val_3core
    .then(deploy_service("alice", "hash1", 3000, "refine", "acc", "on_msg"))
    .then(deploy_service("bob", "hash2", 3000, "refine", "acc", "on_msg"))
    .then(deploy_service("charlie", "hash3", 3000, "refine", "acc", "on_msg"))
    // Submit work packages to all 3 cores simultaneously
    .then(submit_work_package(0, wi_set_small, "auth1"))
    .then(submit_work_package(1, wi_set_medium, "auth2"))
    .then(submit_work_package(2, wi_set_large, "auth3"))
    // Process all work packages
    .then(refine_work_package(0))
    .then(refine_work_package(1))
    .then(refine_work_package(2))
    .then(accumulate_work_results(Set(0, 1, 2)))
    .expect(and {
      // All 3 work packages processed successfully
      work_results.keys().size() == 3,
      work_results.keys().forall(id => work_results.get(id).success),
      // All cores are now available again
      cores.keys().forall(core_id => cores.get(core_id).state == Available),
      // State updated after accumulation
      jam_state_root == "state_accumulated"
    })
  }

  // Test: Gas limit enforcement across 3 cores
  run test_gas_limit_enforcement_3cores = {
    init_5val_3core
    .then(deploy_service("alice", "hash1", 3000, "refine", "acc", "on_msg"))
    // Try to submit work package that exceeds MAX_GAS_PER_BLOCK
    .then(submit_work_package(0, Set({
      id: 0,
      service_id: 0,
      payload: "huge_payload",
      gas_limit: MAX_GAS_PER_BLOCK + 1000,
      status: WorkPending,
      refine_output: "",
      accumulate_input: ""
    }), "auth1"))
    .expect(and {
      // Work package should be rejected due to gas limit
      pending_work_packages.size() == 0,
      // All cores remain available
      cores.keys().forall(core_id => cores.get(core_id).state == Available)
    })
  }

  // Test: Concurrent work package processing
  run test_concurrent_processing = {
    init_5val_3core
    .then(deploy_service("alice", "hash1", 5000, "refine", "acc", "on_msg"))
    // Submit multiple work packages rapidly
    .then(submit_work_package(0, wi_set_small, "auth1"))
    .then(submit_work_package(0, wi_set_medium, "auth2"))
    .then(submit_work_package(0, wi_set_large, "auth3"))
    .expect(and {
      // All 3 cores should be occupied
      pending_work_packages.size() == 3,
      cores.get(0).state == Occupied,
      cores.get(1).state == Occupied,
      cores.get(2).state == Occupied,
      // Each core has a different work package
      cores.get(0).current_package != cores.get(1).current_package,
      cores.get(1).current_package != cores.get(2).current_package,
      cores.get(0).current_package != cores.get(2).current_package
    })
  }

  // Test: Work package batching and accumulation limits
  run test_accumulation_batching = {
    init_5val_3core
    .then(deploy_service("alice", "hash1", 5000, "refine", "acc", "on_msg"))
    .then(deploy_service("bob", "hash2", 5000, "refine", "acc", "on_msg"))
    .then(deploy_service("charlie", "hash3", 5000, "refine", "acc", "on_msg"))
    // Submit and process multiple work packages
    .then(submit_work_package(0, wi_set_small, "auth1"))
    .then(submit_work_package(1, wi_set_medium, "auth2"))
    .then(submit_work_package(2, wi_set_large, "auth3"))
    .then(refine_work_package(0))
    .then(refine_work_package(1))
    .then(refine_work_package(2))
    // Try to accumulate more than the limit (10)
    .then(accumulate_work_results(Set(0, 1, 2)))
    .expect(and {
      // All results should be accumulated (within limit)
      work_results.keys().size() == 3,
      work_results.keys().forall(id => work_results.get(id).success),
      jam_state_root == "state_accumulated"
    })
  }

  // Test: Resource contention with limited cores
  run test_resource_contention = {
    init_5val_3core
    .then(deploy_service("alice", "hash1", 5000, "refine", "acc", "on_msg"))
    .then(deploy_service("bob", "hash2", 5000, "refine", "acc", "on_msg"))
    // Submit 4 work packages but only have 3 cores
    .then(submit_work_package(0, wi_set_small, "auth1"))
    .then(submit_work_package(1, wi_set_medium, "auth2"))
    .then(submit_work_package(0, wi_set_large, "auth3"))
    .then(submit_work_package(1, wi_set_small, "auth4")) // Should fail - no cores available
    .expect(and {
      // Only 3 work packages should be accepted
      pending_work_packages.size() == 3,
      // All cores occupied
      cores.keys().forall(core_id => cores.get(core_id).state == Occupied)
    })
  }

  // Test: Core recovery after work package completion
  run test_core_recovery = {
    init_5val_3core
    .then(deploy_service("alice", "hash1", 3000, "refine", "acc", "on_msg"))
    .then(submit_work_package(0, wi_set_small, "auth1"))
    .then(refine_work_package(0)) // This should free the core
    .then(submit_work_package(0, wi_set_medium, "auth2")) // Should succeed now
    .expect(and {
      // Second work package should be accepted
      pending_work_packages.size() == 1,
      // One core should be occupied by the new package
      cores.keys().exists(core_id => cores.get(core_id).state == Occupied),
      // Work result from first package exists
      work_results.keys().contains(0)
    })
  }

  // Test: Validator load balancing across 3 cores
  run test_validator_load_balancing = {
    init_5val_3core
    .then(all {
      // Assign validators to cores manually for testing
      validator_assignments' = Map(
        0 -> Set("val1", "val2"),
        1 -> Set("val3", "val4"),
        2 -> Set("val5")
      ),
      validators' = validators
        .setBy(0, v => { ...v, core_assignments: Set(0) })
        .setBy(1, v => { ...v, core_assignments: Set(0) })
        .setBy(2, v => { ...v, core_assignments: Set(1) })
        .setBy(3, v => { ...v, core_assignments: Set(1) })
        .setBy(4, v => { ...v, core_assignments: Set(2) }),
      current_block' = current_block,
      services' = services,
      accounts' = accounts,
      pending_calls' = pending_calls,
      next_service_id' = next_service_id,
      cores' = cores,
      work_packages' = work_packages,
      work_results' = work_results,
      pending_work_packages' = pending_work_packages,
      next_package_id' = next_package_id,
      next_work_item_id' = next_work_item_id,
      jam_state_root' = jam_state_root,
      entropy_pool' = entropy_pool,
      blocks' = blocks,
      chain_head' = chain_head,
      current_epoch' = current_epoch,
      pending_extrinsics' = pending_extrinsics,
      next_extrinsic_id' = next_extrinsic_id,
      validator_count' = validator_count,
      tickets' = tickets,
      pending_tickets' = pending_tickets,
      current_slot' = current_slot,
      entropy_accumulator' = entropy_accumulator,
      finalized_blocks' = finalized_blocks,
      grandpa_round' = grandpa_round,
      pending_votes' = pending_votes,
      finality_justifications' = finality_justifications,
      pvm_programs' = pvm_programs,
      pvm_contexts' = pvm_contexts,
      pvm_gas_used' = pvm_gas_used,
      data_blobs' = data_blobs,
      data_segments' = data_segments,
      next_blob_id' = next_blob_id,
      availability_threshold' = availability_threshold,
      disputes' = disputes,
      next_dispute_id' = next_dispute_id,
      slashing_events' = slashing_events,
      scheduled_packages' = scheduled_packages,
      scheduling_policy' = scheduling_policy,
      parachains' = parachains,
      xcmp_messages' = xcmp_messages,
      next_xcmp_message_id' = next_xcmp_message_id
    })
    .expect(and {
      // Core 0 has 2 validators
      validator_assignments.get(0).size() == 2,
      // Core 1 has 2 validators
      validator_assignments.get(1).size() == 2,
      // Core 2 has 1 validator
      validator_assignments.get(2).size() == 1,
      // All 5 validators are assigned
      validator_assignments.keys().fold(0, (total, core_id) => 
        total + validator_assignments.get(core_id).size()) == 5,
      // Each validator is assigned to exactly one core
      validators.keys().forall(v_idx => validators.get(v_idx).core_assignments.size() == 1)
    })
  }

  // Test: System stability under high load
  run test_system_stability_high_load = {
    init_5val_3core
    .then(deploy_service("alice", "hash1", 8000, "refine", "acc", "on_msg"))
    .then(deploy_service("bob", "hash2", 8000, "refine", "acc", "on_msg"))
    .then(deploy_service("charlie", "hash3", 8000, "refine", "acc", "on_msg"))
    // Rapid succession of work packages
    .then(submit_work_package(0, wi_set_large, "auth1"))
    .then(submit_work_package(1, wi_set_large, "auth2"))
    .then(submit_work_package(2, wi_set_large, "auth3"))
    .then(refine_work_package(0))
    .then(refine_work_package(1))
    .then(refine_work_package(2))
    .then(accumulate_work_results(Set(0, 1, 2)))
    .expect(and {
      // System should remain stable
      system_invariant,
      // All work processed successfully
      work_results.keys().size() == 3,
      work_results.keys().forall(id => work_results.get(id).success),
      // All cores available for next round
      cores.keys().forall(core_id => cores.get(core_id).state == Available),
      // Validator count unchanged
      validator_count == 5,
      // Core count unchanged
      cores.keys().size() == 3
    })
  }
}
