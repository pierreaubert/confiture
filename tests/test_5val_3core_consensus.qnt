module test_5val_3core_consensus {
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

  // Test: GRANDPA voting with 5 validators (3/5 threshold)
  run test_grandpa_voting_5validators = {
    init_5val_3core
    .then(all {
      // Add prevotes from 3 validators (majority)
      pending_votes' = Set(
        {
          voter_index: 0,
          vote_type: Prevote,
          target_hash: "block_hash_1",
          target_number: 1,
          signature: "sig_0",
          round_number: 1
        },
        {
          voter_index: 1,
          vote_type: Prevote,
          target_hash: "block_hash_1",
          target_number: 1,
          signature: "sig_1",
          round_number: 1
        },
        {
          voter_index: 2,
          vote_type: Prevote,
          target_hash: "block_hash_1",
          target_number: 1,
          signature: "sig_2",
          round_number: 1
        }
      ),
      grandpa_round' = 1,
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
      validators' = validators,
      validator_count' = validator_count,
      tickets' = tickets,
      pending_tickets' = pending_tickets,
      current_slot' = current_slot,
      entropy_accumulator' = entropy_accumulator,
      finalized_blocks' = finalized_blocks,
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
      // 3 out of 5 validators voted (60% > 2/3 threshold)
      pending_votes.size() == 3,
      pending_votes.filter(vote => vote.vote_type == Prevote).size() == 3,
      grandpa_round == 1,
      validator_count == 5
    })
  }

  // Test: Insufficient GRANDPA votes (only 2 out of 5)
  run test_insufficient_grandpa_votes = {
    init_5val_3core
    .then(all {
      // Add prevotes from only 2 validators (insufficient)
      pending_votes' = Set(
        {
          voter_index: 0,
          vote_type: Prevote,
          target_hash: "block_hash_1",
          target_number: 1,
          signature: "sig_0",
          round_number: 1
        },
        {
          voter_index: 1,
          vote_type: Prevote,
          target_hash: "block_hash_1",
          target_number: 1,
          signature: "sig_1",
          round_number: 1
        }
      ),
      grandpa_round' = 1,
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
      validators' = validators,
      validator_count' = validator_count,
      tickets' = tickets,
      pending_tickets' = pending_tickets,
      current_slot' = current_slot,
      entropy_accumulator' = entropy_accumulator,
      finalized_blocks' = finalized_blocks,
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
      // Only 2 out of 5 validators voted (40% < 2/3 threshold)
      pending_votes.size() == 2,
      pending_votes.filter(vote => vote.vote_type == Prevote).size() == 2,
      validator_count == 5,
      // Should not reach finalization threshold
      pending_votes.size() < (validator_count * 2 / 3)
    })
  }

  // Test: Ticket distribution among 5 validators
  run test_ticket_distribution_5validators = {
    init_5val_3core
    .then(all {
      // Create tickets for all 5 validators
      tickets' = TEST_VALIDATORS.fold(Map(), (acc, val_name) => {
        val idx = TEST_VALIDATORS.fold(0, (count, v) => if (v == val_name) count else count + 1)
        val ticket_id = if (val_name == "val1") "ticket_val1"
                       else if (val_name == "val2") "ticket_val2"
                       else if (val_name == "val3") "ticket_val3"
                       else if (val_name == "val4") "ticket_val4"
                       else "ticket_val5"
        acc.put(ticket_id, {
          id: ticket_id,
          validator_index: idx,
          slot_number: idx + 1,
          status: TicketPending,
          entropy_input: if (val_name == "val1") "entropy_val1"
                        else if (val_name == "val2") "entropy_val2"
                        else if (val_name == "val3") "entropy_val3"
                        else if (val_name == "val4") "entropy_val4"
                        else "entropy_val5",
          signature: if (val_name == "val1") "sig_val1"
                    else if (val_name == "val2") "sig_val2"
                    else if (val_name == "val3") "sig_val3"
                    else if (val_name == "val4") "sig_val4"
                    else "sig_val5"
        })
      }),
      current_slot' = 5,
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
      validators' = validators,
      validator_count' = validator_count,
      pending_tickets' = pending_tickets,
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
      // All 5 validators have tickets
      tickets.keys().size() == 5,
      tickets.keys().contains("ticket_val1"),
      tickets.keys().contains("ticket_val2"),
      tickets.keys().contains("ticket_val3"),
      tickets.keys().contains("ticket_val4"),
      tickets.keys().contains("ticket_val5"),
      // Each validator has a unique slot
      tickets.keys().forall(ticket_id => 
        tickets.get(ticket_id).slot_number >= 1 and tickets.get(ticket_id).slot_number <= 5),
      current_slot == 5
    })
  }

  // Test: Dispute resolution with 5 validators
  run test_dispute_resolution_5validators = {
    init_5val_3core
    .then(initiate_dispute("val1", "val2", InvalidWorkPackage, "evidence_data"))
    .then(all {
      // Add resolution votes from 3 validators (majority)
      disputes' = disputes.setBy(0, dispute => {
        ...dispute,
        resolution_votes: Set("val1", "val3", "val4")
      }),
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
      validators' = validators,
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
      next_dispute_id' = next_dispute_id,
      slashing_events' = slashing_events,
      scheduled_packages' = scheduled_packages,
      scheduling_policy' = scheduling_policy,
      parachains' = parachains,
      xcmp_messages' = xcmp_messages,
      next_xcmp_message_id' = next_xcmp_message_id
    })
    .expect(and {
      // Dispute exists and has majority votes
      disputes.keys().contains(0),
      disputes.get(0).resolution_votes.size() == 3,
      disputes.get(0).target_validator == "val2",
      disputes.get(0).initiated_by == "val1",
      // 3 out of 5 is majority (60%)
      disputes.get(0).resolution_votes.size() > validator_count / 2
    })
  }

  // Test: Block production with 5 validators and 3 cores
  run test_block_production_5val_3core = {
    init_5val_3core
    .then(deploy_service("alice", "hash_code", 2000, "refine", "acc", "on_msg"))
    .then(submit_work_package(0, Set({
      id: 0,
      service_id: 0,
      payload: "payload0",
      gas_limit: 5000,
      status: WorkPending,
      refine_output: "",
      accumulate_input: ""
    }), "auth_sig"))
    .then(refine_work_package(0))
    .then(accumulate_work_results(Set(0)))
    .then(all {
      // Simulate block production
      current_block' = current_block + 1,
      blocks' = blocks.put(current_block + 1, {
        header: {
          parent_hash: "parent_hash",
          block_number: current_block + 1,
          state_root: jam_state_root,
          extrinsics_root: "extrinsics_root",
          entropy_pool_root: entropy_pool,
          timestamp: (current_block + 1) * 6000,
          epoch: 0,
          winning_tickets: Set(),
          offenders_markers: Set(),
          author_index: 0,
          seal: "block_seal"
        },
        extrinsics: Set(),
        guarantees: Set(),
        assurances: Set(),
        preimages: Set(),
        availability: Set()
      }),
      chain_head' = current_block + 1,
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
      current_epoch' = current_epoch,
      pending_extrinsics' = pending_extrinsics,
      next_extrinsic_id' = next_extrinsic_id,
      validators' = validators,
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
      // Block was produced successfully
      current_block == 1,
      chain_head == 1,
      blocks.keys().contains(1),
      blocks.get(1).header.block_number == 1,
      // Work was processed successfully
      work_results.keys().contains(0),
      work_results.get(0).success,
      // System maintains 5 validators and 3 cores
      validator_count == 5,
      cores.keys().size() == 3
    })
  }
}
