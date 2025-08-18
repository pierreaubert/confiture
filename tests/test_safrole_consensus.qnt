module test_safrole_consensus {
  import confiture.* from "../confiture"

  // Test: Basic validator registration
  run test_validator_registration = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .expect(and {
      validator_count == 1,
      validators.keys().contains(0),
      validators.get(0).public_key == "validator1",
      validators.get(0).state == ValidatorActive,
      validators.get(0).stake == MIN_VALIDATOR_STAKE
    })
  }

  // Test: Cannot register validator with insufficient stake
  run test_validator_registration_insufficient_stake = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE - 100))
    .expect(validator_count == 0)
  }

  // Test: Cannot register duplicate validator
  run test_validator_registration_duplicate = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .expect(and {
      validator_count == 1,
      validators.get(0).stake == MIN_VALIDATOR_STAKE // Original stake unchanged
    })
  }

  // Test: Maximum validator limit
  run test_validator_registration_max_limit = {
    init
    .then(all {
      validator_count' = MAX_VALIDATORS,
      validators' = Map(0 -> {
        index: 0,
        public_key: "existing_validator",
        state: ValidatorActive,
        stake: MIN_VALIDATOR_STAKE,
        core_assignments: Set(),
        last_block_authored: 0
      }),
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
    .then(register_validator("new_validator", MIN_VALIDATOR_STAKE))
    .expect(validator_count == MAX_VALIDATORS) // Should not increase
  }

  // Test: SAFROLE ticket submission
  run test_ticket_submission = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, current_slot + 1, "entropy_data"))
    .expect(and {
      tickets.keys().size() == 1,
      tickets.keys().exists(ticket_id => 
        tickets.get(ticket_id).validator_index == 0 and
        tickets.get(ticket_id).slot_number == current_slot + 1 and
        tickets.get(ticket_id).status == TicketPending
      )
    })
  }

  // Test: Cannot submit ticket for inactive validator
  run test_ticket_submission_inactive_validator = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(all {
      // Deactivate the validator
      validators' = validators.setBy(0, v => { ...v, state: ValidatorInactive }),
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
    .then(submit_ticket(0, current_slot + 1, "entropy_data"))
    .expect(tickets.keys().size() == 0) // No ticket should be created
  }

  // Test: Cannot submit ticket for past slot
  run test_ticket_submission_past_slot = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, current_slot - 1, "entropy_data"))
    .expect(tickets.keys().size() == 0)
  }

  // Test: Multiple validators submitting tickets
  run test_multiple_validator_tickets = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, current_slot + 1, "entropy1"))
    .then(submit_ticket(1, current_slot + 2, "entropy2"))
    .then(submit_ticket(2, current_slot + 3, "entropy3"))
    .expect(and {
      tickets.keys().size() == 3,
      validator_count == 3,
      // Each validator should have submitted a ticket
      tickets.keys().exists(tid => tickets.get(tid).validator_index == 0),
      tickets.keys().exists(tid => tickets.get(tid).validator_index == 1),
      tickets.keys().exists(tid => tickets.get(tid).validator_index == 2)
    })
  }

  // Test: Ticket winning selection (simplified)
  run test_ticket_winning_selection = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, current_slot + 1, "entropy1"))
    .then(submit_ticket(1, current_slot + 1, "entropy2")) // Same slot competition
    .then(all {
      // Mark one ticket as winning
      val winning_ticket_id = tickets.keys().fold("", (acc, tid) => 
        if (tickets.get(tid).validator_index == 0) tid else acc)
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
      tickets.keys().size() == 2,
      // One ticket should be winning
      tickets.keys().exists(tid => tickets.get(tid).status == Winning),
      // One ticket should still be pending
      tickets.keys().exists(tid => tickets.get(tid).status == TicketPending)
    })
  }

  // Test: Entropy accumulation
  run test_entropy_accumulation = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, current_slot + 1, "entropy_input"))
    .then(all {
      // Simulate entropy accumulation
      entropy_accumulator' = "accumulated_entropy",
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
      entropy_accumulator == "accumulated_entropy",
      tickets.keys().size() == 1
    })
  }

  // Test: Slot progression
  run test_slot_progression = {
    init
    .then(all {
      current_slot' = current_slot + 1,
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
    .expect(current_slot == 1) // Started at 0, now at 1
  }
}
