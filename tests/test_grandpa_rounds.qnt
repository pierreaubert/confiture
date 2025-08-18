module test_grandpa_rounds {
  import confiture.* from "../confiture"

  // Test: Basic round progression
  run test_basic_round_progression = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(all {
      // Advance GRANDPA round
      grandpa_round' = grandpa_round + 1,
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
      grandpa_round == 1,
      validators.keys().size() == 2
    })
  }

  // Test: Round duration timing
  run test_round_duration_timing = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(all {
      // Simulate time passage equal to GRANDPA_ROUND_DURATION
      grandpa_round' = grandpa_round + 1,
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
      grandpa_round == 1,
      GRANDPA_ROUND_DURATION == 30  // Verify constant
    })
  }

  // Test: Vote clearing between rounds
  run test_vote_clearing_between_rounds = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(all {
      // Advance round and clear votes
      grandpa_round' = grandpa_round + 1,
      pending_votes' = Set(),  // Clear votes for new round
      current_block' = current_block,
      validators' = validators,
      validator_count' = validator_count,
      accounts' = accounts,
      services' = services,
      next_service_id' = next_service_id,
      pending_calls' = pending_calls,
      cores' = cores,
      work_packages' = work_packages,
      work_results' = work_results,
      pending_work_packages' = pending_work_packages,
      next_package_id' = next_package_id,
      next_work_item_id' = next_work_item_id,
      blocks' = blocks,
      chain_head' = chain_head,
      jam_state_root' = jam_state_root,
      entropy_pool' = entropy_pool,
      validator_assignments' = validator_assignments,
      current_epoch' = current_epoch,
      pending_extrinsics' = pending_extrinsics,
      next_extrinsic_id' = next_extrinsic_id,
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
      grandpa_round == 1,
      pending_votes.size() == 0
    })
  }

  // Test: Multiple rounds with different votes
  run test_multiple_rounds_different_votes = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(produce_block)
    .then(produce_block)
    // Round 0: Vote for block 1
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(all {
      // Advance to round 1
      grandpa_round' = grandpa_round + 1,
      pending_votes' = Set(),
      current_block' = current_block,
      validators' = validators,
      validator_count' = validator_count,
      accounts' = accounts,
      services' = services,
      next_service_id' = next_service_id,
      pending_calls' = pending_calls,
      cores' = cores,
      work_packages' = work_packages,
      work_results' = work_results,
      pending_work_packages' = pending_work_packages,
      next_package_id' = next_package_id,
      next_work_item_id' = next_work_item_id,
      blocks' = blocks,
      chain_head' = chain_head,
      jam_state_root' = jam_state_root,
      entropy_pool' = entropy_pool,
      validator_assignments' = validator_assignments,
      current_epoch' = current_epoch,
      pending_extrinsics' = pending_extrinsics,
      next_extrinsic_id' = next_extrinsic_id,
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
    // Round 1: Vote for block 2
    .then(submit_grandpa_vote(0, Prevote, "block_hash_2", 2))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_2", 2))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_2", 2))
    .then(all {
      // Advance to round 2
      grandpa_round' = grandpa_round + 1,
      pending_votes' = Set(),
      current_block' = current_block,
      validators' = validators,
      validator_count' = validator_count,
      accounts' = accounts,
      services' = services,
      next_service_id' = next_service_id,
      pending_calls' = pending_calls,
      cores' = cores,
      work_packages' = work_packages,
      work_results' = work_results,
      pending_work_packages' = pending_work_packages,
      next_package_id' = next_package_id,
      next_work_item_id' = next_work_item_id,
      blocks' = blocks,
      chain_head' = chain_head,
      jam_state_root' = jam_state_root,
      entropy_pool' = entropy_pool,
      validator_assignments' = validator_assignments,
      current_epoch' = current_epoch,
      pending_extrinsics' = pending_extrinsics,
      next_extrinsic_id' = next_extrinsic_id,
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
    // Round 2: Vote for block 3
    .then(submit_grandpa_vote(0, Prevote, "block_hash_3", 3))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_3", 3))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_3", 3))
    .expect(and {
      grandpa_round == 2,
      pending_votes.size() == 3,
      pending_votes.filter(v => v.target_number == 3).size() == 3
    })
  }

  // Test: Round timeout and progression
  run test_round_timeout_progression = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    // Submit insufficient votes in round 0
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(all {
      // Simulate timeout and round progression
      grandpa_round' = grandpa_round + 1,
      pending_votes' = Set(),  // Clear stale votes
      current_block' = current_block,
      validators' = validators,
      validator_count' = validator_count,
      accounts' = accounts,
      services' = services,
      next_service_id' = next_service_id,
      pending_calls' = pending_calls,
      cores' = cores,
      work_packages' = work_packages,
      work_results' = work_results,
      pending_work_packages' = pending_work_packages,
      next_package_id' = next_package_id,
      next_work_item_id' = next_work_item_id,
      blocks' = blocks,
      chain_head' = chain_head,
      jam_state_root' = jam_state_root,
      entropy_pool' = entropy_pool,
      validator_assignments' = validator_assignments,
      current_epoch' = current_epoch,
      pending_extrinsics' = pending_extrinsics,
      next_extrinsic_id' = next_extrinsic_id,
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
      grandpa_round == 1,
      pending_votes.size() == 0,
      not(finalized_blocks.contains(1))  // Block not finalized due to timeout
    })
  }

  // Test: Round consistency across validator set
  run test_round_consistency_validator_set = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator4", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Prevote, "block_hash_1", 1))
    .expect(and {
      // All votes should be in the same round
      pending_votes.filter(v => v.round_number == grandpa_round).size() == 4,
      pending_votes.filter(v => v.round_number != grandpa_round).size() == 0,
      validators.keys().size() == 4
    })
  }

  // Test: Round advancement with partial finalization
  run test_round_advancement_partial_finalization = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator4", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator5", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator6", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(produce_block)
    // Round 0: Partial votes for block 1
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))
    .then(all {
      // Advance round without finalization
      grandpa_round' = grandpa_round + 1,
      pending_votes' = Set(),
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
    // Round 1: Complete finalization for block 2
    .then(submit_grandpa_vote(0, Prevote, "block_hash_2", 2))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_2", 2))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_2", 2))
    .then(submit_grandpa_vote(3, Prevote, "block_hash_2", 2))
    .then(submit_grandpa_vote(4, Prevote, "block_hash_2", 2))
    .then(submit_grandpa_vote(0, Precommit, "block_hash_2", 2))
    .then(submit_grandpa_vote(1, Precommit, "block_hash_2", 2))
    .then(submit_grandpa_vote(2, Precommit, "block_hash_2", 2))
    .then(submit_grandpa_vote(3, Precommit, "block_hash_2", 2))
    .then(submit_grandpa_vote(4, Precommit, "block_hash_2", 2))
    .then(finalize_block("block_hash_2", 2))
    .expect(and {
      grandpa_round == 1,
      not(finalized_blocks.contains(1)),  // Block 1 not finalized
      finalized_blocks.contains(2),       // Block 2 finalized in round 1
      finality_justifications.get(2).round_number == 1
    })
  }

  // Test: Long-running rounds with many validators
  run test_long_running_rounds_many_validators = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator4", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator5", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator6", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator7", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator8", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator9", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator10", MIN_VALIDATOR_STAKE))
    .then(all {
      // Advance through multiple rounds
      grandpa_round' = grandpa_round + 10,
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
      grandpa_round == 10,
      validators.keys().size() == 10,
      // System should remain stable across many rounds
      validators.keys().forall(i => validators.get(i).state == ValidatorActive)
    })
  }

  // Test: Round synchronization with block production
  run test_round_synchronization_block_production = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(produce_block)  // Produce another block during voting
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))
    .expect(and {
      // Voting should continue despite new block production
      pending_votes.size() == 3,
      blocks.keys().size() >= 2,  // At least genesis + 2 blocks
      pending_votes.filter(v => v.target_number == 1).size() == 3
    })
  }
}
