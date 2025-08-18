module test_5val_3core_validator_assignment {
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

  // Custom validator assignment action for 3 cores and 5 validators
  action assign_validators_to_3cores(): bool = {
    val active_validators = validators.keys().filter(i => validators.get(i).state == ValidatorActive)
    val can_assign = active_validators.size() >= TEST_CORES

    val new_assignments = if (can_assign) {
      TEST_CORE_INDICES.mapBy(core_id => {
        // Distribute 5 validators across 3 cores
        val assigned_validators = active_validators.filter(v => v % TEST_CORES == core_id)
        assigned_validators.fold(Set(), (acc, v) => acc.union(Set(validators.get(v).public_key)))
      })
    } else {
      TEST_CORE_INDICES.mapBy(_ => Set())
    }

    val updated_validators = if (can_assign) {
      active_validators.fold(validators, (acc, v_idx) => {
        val validator = acc.get(v_idx)
        val assigned_core = v_idx % TEST_CORES
        acc.setBy(v_idx, v => { ...v, core_assignments: Set(assigned_core) })
      })
    } else {
      validators
    }

    all {
      can_assign,
      validator_assignments' = new_assignments,
      validators' = updated_validators,
      // Keep other state unchanged
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
    }
  }

  // Test: Validator assignment to 3 cores
  run test_validator_assignment_3cores = {
    init_5val_3core
    .then(assign_validators_to_3cores)
    .expect(and {
      // All 3 cores should have validators assigned
      validator_assignments.keys().size() == TEST_CORES,
      TEST_CORE_INDICES.forall(core_id => validator_assignments.get(core_id).size() > 0),
      // All 5 validators should be assigned to cores
      validators.keys().forall(v_idx => validators.get(v_idx).core_assignments.size() == 1),
      // Distribution should be balanced (some cores get 2 validators, some get 1)
      validator_assignments.keys().fold(0, (total, core_id) => 
        total + validator_assignments.get(core_id).size()) == 5
    })
  }

  // Test: Validator rotation across cores
  run test_validator_rotation = {
    init_5val_3core
    .then(assign_validators_to_3cores)
    .then(assign_validators_to_3cores) // Second assignment should rotate
    .expect(and {
      // Still have all validators assigned
      validators.keys().forall(v_idx => validators.get(v_idx).core_assignments.size() == 1),
      // All cores still have validators
      TEST_CORE_INDICES.forall(core_id => validator_assignments.get(core_id).size() > 0)
    })
  }

  // Test: Core assignment distribution
  run test_core_assignment_distribution = {
    init_5val_3core
    .then(assign_validators_to_3cores)
    .expect(and {
      // Core 0 should have validators with index % 3 == 0
      validator_assignments.get(0).exists(val_key => 
        validators.keys().exists(idx => 
          validators.get(idx).public_key == val_key and idx % 3 == 0)),
      // Core 1 should have validators with index % 3 == 1
      validator_assignments.get(1).exists(val_key => 
        validators.keys().exists(idx => 
          validators.get(idx).public_key == val_key and idx % 3 == 1)),
      // Core 2 should have validators with index % 3 == 2
      validator_assignments.get(2).exists(val_key => 
        validators.keys().exists(idx => 
          validators.get(idx).public_key == val_key and idx % 3 == 2))
    })
  }

  // Test: Insufficient validators scenario
  run test_insufficient_validators = {
    init_5val_3core
    // Deactivate 3 validators, leaving only 2 active (less than 3 cores)
    .then(all {
      validators' = validators
        .setBy(2, v => { ...v, state: ValidatorInactive })
        .setBy(3, v => { ...v, state: ValidatorInactive })
        .setBy(4, v => { ...v, state: ValidatorInactive }),
      validator_count' = 2,
      // Keep other state unchanged
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
      validator_assignments' = validator_assignments,
      blocks' = blocks,
      chain_head' = chain_head,
      current_epoch' = current_epoch,
      pending_extrinsics' = pending_extrinsics,
      next_extrinsic_id' = next_extrinsic_id,
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
    .then(assign_validators_to_3cores) // Should fail due to insufficient validators
    .expect(and {
      // Assignment should fail, so assignments remain empty
      validator_assignments.keys().forall(core_id => 
        validator_assignments.get(core_id).size() == 0),
      // Only 2 validators are active
      validators.keys().filter(idx => validators.get(idx).state == ValidatorActive).size() == 2
    })
  }
}
