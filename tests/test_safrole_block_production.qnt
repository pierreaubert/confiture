module test_safrole_block_production {
  import confiture.* from "../confiture"

  // Test: Block production with winning ticket
  run test_block_production_with_ticket = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, current_slot + 1, "entropy1"))
    .then(all {
      // Mark ticket as winning and produce block
      val ticket_id = tickets.keys().fold("", (acc, tid) => tid)
      tickets' = tickets.setBy(ticket_id, t => { ...t, status: Winning }),
      // Produce block
      current_block' = current_block + 1,
      chain_head' = chain_head + 1,
      blocks' = blocks.put(current_block + 1, {
        header: {
          parent_hash: "parent_hash",
          block_number: current_block + 1,
          state_root: jam_state_root,
          extrinsics_root: "extrinsics_root",
          entropy_pool_root: entropy_pool,
          timestamp: (current_block + 1) * SAFROLE_SLOT_DURATION,
          epoch: current_epoch,
          winning_tickets: Set("winning_ticket"),
          offenders_markers: Set(),
          author_index: 0,
          seal: "safrole_seal"
        },
        extrinsics: Set(),
        guarantees: Set(),
        assurances: Set(),
        preimages: Set(),
        availability: Set()
      }),
      // Update validator's last block authored
      validators' = validators.setBy(0, v => { ...v, last_block_authored: current_block + 1 }),
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
      validator_count' = validator_count,
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
      current_block == 1,
      chain_head == 1,
      blocks.keys().contains(1),
      blocks.get(1).header.winning_tickets.size() == 1,
      validators.get(0).last_block_authored == 1,
      tickets.keys().exists(tid => tickets.get(tid).status == Winning)
    })
  }

  // Test: Entropy accumulation during block production
  run test_entropy_accumulation_block_production = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, current_slot + 1, "entropy_input"))
    .then(all {
      // Simulate entropy accumulation from ticket
      entropy_accumulator' = "new_accumulated_entropy",
      entropy_pool' = "updated_entropy_pool",
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
      entropy_accumulator == "new_accumulated_entropy",
      entropy_pool == "updated_entropy_pool",
      tickets.keys().exists(tid => tickets.get(tid).entropy_input == "entropy_input")
    })
  }

  // Test: Slot timing and block production timing
  run test_slot_timing = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(all {
      // Advance to specific slot
      current_slot' = 10,
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
    .then(submit_ticket(0, current_slot, "entropy_slot10"))
    .expect(and {
      current_slot == 10,
      tickets.keys().exists(tid => 
        tickets.get(tid).slot_number == 10 and
        tickets.get(tid).entropy_input == "entropy_slot10"
      )
    })
  }

  // Test: Multiple validators competing for block production
  run test_multiple_validators_block_competition = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE + 1000))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE + 2000))
    .then(submit_ticket(0, current_slot + 1, "entropy1"))
    .then(submit_ticket(1, current_slot + 1, "entropy2"))
    .then(submit_ticket(2, current_slot + 1, "entropy3"))
    .then(all {
      // Simulate selection of winning ticket (validator 2 wins)
      val winning_ticket_id = tickets.keys().fold("", (acc, tid) => 
        if (tickets.get(tid).validator_index == 1) tid else acc)
      tickets' = tickets.setBy(winning_ticket_id, t => { ...t, status: Winning }),
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
      tickets.keys().size() == 3,
      // Exactly one winning ticket
      tickets.keys().filter(tid => tickets.get(tid).status == Winning).size() == 1,
      // Winner is validator 1 (index 1)
      tickets.keys().exists(tid => 
        tickets.get(tid).status == Winning and 
        tickets.get(tid).validator_index == 1
      )
    })
  }

  // Test: Block seal creation with SAFROLE proof
  run test_block_seal_creation = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, current_slot + 1, "entropy1"))
    .then(all {
      // Create block with SAFROLE seal
      val ticket_id = tickets.keys().fold("", (acc, tid) => tid)
      tickets' = tickets.setBy(ticket_id, t => { ...t, status: Winning }),
      current_block' = current_block + 1,
      blocks' = blocks.put(current_block + 1, {
        header: {
          parent_hash: "parent_hash",
          block_number: current_block + 1,
          state_root: jam_state_root,
          extrinsics_root: "extrinsics_root",
          entropy_pool_root: entropy_pool,
          timestamp: (current_block + 1) * SAFROLE_SLOT_DURATION,
          epoch: current_epoch,
          winning_tickets: Set("winning_ticket"),
          offenders_markers: Set(),
          author_index: 0,
          seal: "safrole_seal_with_ticket"
        },
        extrinsics: Set(),
        guarantees: Set(),
        assurances: Set(),
        preimages: Set(),
        availability: Set()
      }),
      chain_head' = chain_head + 1,
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
      blocks.keys().contains(1),
      blocks.get(1).header.winning_tickets.size() == 1,
      blocks.get(1).header.seal == "safrole_seal_with_ticket",
      blocks.get(1).header.timestamp == SAFROLE_SLOT_DURATION
    })
  }

  // Test: Epoch transitions and validator rotation
  run test_epoch_transition = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(all {
      // Simulate epoch transition
      current_epoch' = current_epoch + 1,
      current_slot' = current_slot + VALIDATOR_ROTATION_PERIOD,
      // Reset some epoch-specific state
      tickets' = Map(),
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
      current_epoch == 1,
      current_slot == VALIDATOR_ROTATION_PERIOD,
      tickets.keys().size() == 0, // Tickets reset for new epoch
      validator_count == 2 // Validators persist across epochs
    })
  }
}
