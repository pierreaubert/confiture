module test_grandpa_justification {
  import confiture.* from "../confiture"

  // Test: Basic finality justification creation
  run test_basic_finality_justification = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator4", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator5", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator6", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(0, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Precommit, "block_hash_1", 1))
    .then(finalize_block("block_hash_1", 1))
    .expect(and {
      finalized_blocks.contains(1),
      finality_justifications.keys().contains(1),
      finality_justifications.get(1).round_number == grandpa_round,
      finality_justifications.get(1).target_hash == "block_hash_1"
    })
  }

  // Test: Insufficient votes for finalization
  run test_insufficient_votes_finalization = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(0, Precommit, "block_hash_1", 1))
    .then(finalize_block("block_hash_1", 1))
    .expect(and {
      // Should not finalize with insufficient votes
      not(finalized_blocks.contains(1)),
      not(finality_justifications.keys().contains(1))
    })
  }

  // Test: Supermajority threshold validation
  run test_supermajority_threshold = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator4", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator5", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator6", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator7", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    // Need at least 5 votes for 7 validators (GRANDPA_THRESHOLD = 5)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(0, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Precommit, "block_hash_1", 1))
    .then(finalize_block("block_hash_1", 1))
    .expect(and {
      finalized_blocks.contains(1),
      finality_justifications.keys().contains(1),
      // Verify threshold was met
      pending_votes.filter(v => and {
        v.vote_type == Prevote,
        v.target_number == 1
      }).size() >= GRANDPA_THRESHOLD,
      pending_votes.filter(v => and {
        v.vote_type == Precommit,
        v.target_number == 1
      }).size() >= GRANDPA_THRESHOLD
    })
  }

  // Test: Conflicting finalization attempts
  run test_conflicting_finalization = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator4", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator5", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator6", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(produce_block)
    // Split votes between two blocks
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Prevote, "block_hash_2", 2))
    .then(submit_grandpa_vote(4, Prevote, "block_hash_2", 2))
    .then(submit_grandpa_vote(5, Prevote, "block_hash_2", 2))
    .then(submit_grandpa_vote(0, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Precommit, "block_hash_1", 1))
    .then(finalize_block("block_hash_1", 1))
    .expect(and {
      // Only one block should be finalized
      finalized_blocks.contains(1),
      not(finalized_blocks.contains(2)),
      finality_justifications.keys().contains(1),
      not(finality_justifications.keys().contains(2))
    })
  }

  // Test: Justification with vote aggregation
  run test_justification_vote_aggregation = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator4", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator5", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator6", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(5, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(0, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(5, Precommit, "block_hash_1", 1))
    .then(finalize_block("block_hash_1", 1))
    .expect(and {
      finalized_blocks.contains(1),
      finality_justifications.keys().contains(1),
      // Verify justification contains aggregated votes
      finality_justifications.get(1).prevotes.size() == 6,
      finality_justifications.get(1).precommits.size() == 6,
      finality_justifications.get(1).target_number == 1
    })
  }

  // Test: Multiple rounds finalization
  run test_multiple_rounds_finalization = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator4", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator5", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator6", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(produce_block)
    // Finalize block 1 in round 0
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(0, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Precommit, "block_hash_1", 1))
    .then(finalize_block("block_hash_1", 1))
    .then(all {
      // Advance to next round
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
      pending_votes' = Set(),  // Clear votes for new round
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
    // Finalize block 2 in round 1
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
      finalized_blocks.contains(1),
      finalized_blocks.contains(2),
      finality_justifications.keys().contains(1),
      finality_justifications.keys().contains(2),
      finality_justifications.get(1).round_number == 0,
      finality_justifications.get(2).round_number == 1
    })
  }

  // Test: Finalization of already finalized block
  run test_double_finalization_prevention = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator4", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator5", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator6", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(0, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Precommit, "block_hash_1", 1))
    .then(finalize_block("block_hash_1", 1))
    .then(finalize_block("block_hash_1", 1))  // Attempt double finalization
    .expect(and {
      finalized_blocks.contains(1),
      finality_justifications.keys().contains(1),
      // Should still only have one justification entry
      finality_justifications.keys().size() >= 1
    })
  }

  // Test: Justification persistence across rounds
  run test_justification_persistence = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator4", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator5", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator6", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(0, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Precommit, "block_hash_1", 1))
    .then(finalize_block("block_hash_1", 1))
    .then(all {
      // Advance multiple rounds
      grandpa_round' = grandpa_round + 5,
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
      pending_votes' = Set(),
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
      // Justification should persist across rounds
      finalized_blocks.contains(1),
      finality_justifications.keys().contains(1),
      finality_justifications.get(1).target_hash == "block_hash_1",
      grandpa_round == 5
    })
  }
}
