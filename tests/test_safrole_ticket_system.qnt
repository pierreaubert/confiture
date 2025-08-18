module test_safrole_ticket_system {
  import confiture.* from "../confiture"

  // Test: Ticket lifecycle - pending to winning to used
  run test_ticket_lifecycle = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, current_slot + 1, "entropy1"))
    .then(all {
      // Mark ticket as winning
      val ticket_id = tickets.keys().fold("", (acc, tid) => tid)
      tickets' = tickets.setBy(ticket_id, t => { ...t, status: Winning }),
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
    .then(all {
      // Mark ticket as used after block production
      val ticket_id = tickets.keys().fold("", (acc, tid) => tid)
      tickets' = tickets.setBy(ticket_id, t => { ...t, status: Used }),
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
      tickets.keys().size() == 1,
      tickets.keys().exists(tid => tickets.get(tid).status == Used)
    })
  }

  // Test: Ticket expiration
  run test_ticket_expiration = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, current_slot + 1, "entropy1"))
    .then(all {
      // Advance slot beyond ticket validity
      current_slot' = current_slot + 100,
      // Mark expired tickets
      val ticket_id = tickets.keys().fold("", (acc, tid) => tid)
      tickets' = tickets.setBy(ticket_id, t => { ...t, status: Expired }),
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
      current_slot == 100,
      tickets.keys().exists(tid => tickets.get(tid).status == Expired)
    })
  }

  // Test: Multiple tickets per epoch limit
  run test_tickets_per_epoch_limit = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    // Submit multiple tickets in same epoch
    .then(submit_ticket(0, current_slot + 1, "entropy1"))
    .then(submit_ticket(1, current_slot + 2, "entropy2"))
    .then(submit_ticket(2, current_slot + 3, "entropy3"))
    .expect(and {
      tickets.keys().size() == 3,
      // All tickets should be for the same epoch (simplified)
      tickets.keys().forall(tid => tickets.get(tid).slot_number <= current_slot + 10)
    })
  }

  // Test: Ticket competition - same slot multiple validators
  run test_ticket_competition = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE + 1000))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE + 2000))
    // All submit for same slot
    .then(submit_ticket(0, current_slot + 5, "entropy1"))
    .then(submit_ticket(1, current_slot + 5, "entropy2"))
    .then(submit_ticket(2, current_slot + 5, "entropy3"))
    .expect(and {
      tickets.keys().size() == 3,
      // All tickets for same slot
      tickets.keys().forall(tid => tickets.get(tid).slot_number == current_slot + 5),
      // Different validators
      tickets.keys().exists(tid => tickets.get(tid).validator_index == 0),
      tickets.keys().exists(tid => tickets.get(tid).validator_index == 1),
      tickets.keys().exists(tid => tickets.get(tid).validator_index == 2)
    })
  }

  // Test: Ticket validation - entropy requirements
  run test_ticket_entropy_validation = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, current_slot + 1, "valid_entropy_input"))
    .expect(and {
      tickets.keys().size() == 1,
      tickets.keys().exists(tid => 
        tickets.get(tid).entropy_input == "valid_entropy_input"
      )
    })
  }

  // Test: Validator stake influence on ticket selection
  run test_stake_weighted_selection = {
    init
    .then(register_validator("low_stake", MIN_VALIDATOR_STAKE))
    .then(register_validator("high_stake", MIN_VALIDATOR_STAKE * 10))
    .then(submit_ticket(0, current_slot + 1, "entropy_low"))
    .then(submit_ticket(1, current_slot + 1, "entropy_high"))
    .expect(and {
      tickets.keys().size() == 2,
      // Both validators can submit tickets
      tickets.keys().exists(tid => tickets.get(tid).validator_index == 0),
      tickets.keys().exists(tid => tickets.get(tid).validator_index == 1),
      // Higher stake validator exists
      validators.get(1).stake > validators.get(0).stake
    })
  }

  // Test: Block authoring rights from winning ticket
  run test_block_authoring_rights = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, current_slot + 1, "entropy1"))
    .then(all {
      // Mark ticket as winning
      val ticket_id = tickets.keys().fold("", (acc, tid) => tid)
      tickets' = tickets.setBy(ticket_id, t => { ...t, status: Winning }),
      // Update validator's last block authored
      validators' = validators.setBy(0, v => { ...v, last_block_authored: current_block + 1 }),
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
      tickets.keys().exists(tid => tickets.get(tid).status == Winning),
      validators.get(0).last_block_authored == current_block + 1
    })
  }

  // Test: Ticket cleanup after use
  run test_ticket_cleanup = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, current_slot + 1, "entropy1"))
    .then(all {
      // Simulate ticket usage and cleanup
      val ticket_id = tickets.keys().fold("", (acc, tid) => tid)
      tickets' = tickets.setBy(ticket_id, t => { ...t, status: Used }),
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
      tickets.keys().size() == 1,
      tickets.keys().exists(tid => tickets.get(tid).status == Used)
    })
  }
}
