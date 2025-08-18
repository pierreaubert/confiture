module test_grandpa_voting {
  import confiture.* from "../confiture"

  // Test: Basic GRANDPA vote submission
  run test_basic_vote_submission = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .expect(and {
      pending_votes.size() == 1,
      pending_votes.exists(v => and {
        v.voter_index == 0,
        v.vote_type == Prevote,
        v.target_hash == "block_hash_1",
        v.target_number == 1,
        v.round_number == grandpa_round
      })
    })
  }

  // Test: Multiple validators voting on same block
  run test_multiple_validators_same_block = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))
    .expect(and {
      pending_votes.size() == 3,
      pending_votes.filter(v => and {
        v.vote_type == Prevote,
        v.target_hash == "block_hash_1",
        v.target_number == 1
      }).size() == 3
    })
  }

  // Test: Conflicting votes from different validators
  run test_conflicting_votes = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(produce_block)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_2", 2))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))
    .expect(and {
      pending_votes.size() == 3,
      pending_votes.filter(v => v.target_number == 1).size() == 2,
      pending_votes.filter(v => v.target_number == 2).size() == 1
    })
  }

  // Test: Prevote and precommit sequence
  run test_prevote_precommit_sequence = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(0, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Precommit, "block_hash_1", 1))
    .expect(and {
      pending_votes.size() == 4,
      pending_votes.filter(v => v.vote_type == Prevote).size() == 2,
      pending_votes.filter(v => v.vote_type == Precommit).size() == 2
    })
  }

  // Test: Invalid vote from non-validator
  run test_invalid_vote_non_validator = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(submit_grandpa_vote(999, Prevote, "block_hash_1", 1))
    .expect(and {
      pending_votes.size() == 0,
      // Vote should be rejected
      not(pending_votes.exists(v => v.voter_index == 999))
    })
  }

  // Test: Vote for non-existent block
  run test_vote_nonexistent_block = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_grandpa_vote(0, Prevote, "nonexistent_hash", 999))
    .expect(and {
      pending_votes.size() == 0,
      // Vote should be rejected for non-existent block
      not(pending_votes.exists(v => v.target_number == 999))
    })
  }

  // Test: Round progression with votes
  run test_round_progression = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
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
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .expect(and {
      grandpa_round > 0,
      pending_votes.filter(v => v.round_number == grandpa_round).size() == 1,
      pending_votes.filter(v => v.round_number == grandpa_round - 1).size() == 1
    })
  }

  // Test: Duplicate vote prevention
  run test_duplicate_vote_prevention = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .expect(and {
      // Should only have one vote, duplicates rejected
      pending_votes.size() == 1,
      pending_votes.filter(v => v.voter_index == 0).size() == 1
    })
  }

  // Test: Vote weight validation with stake
  run test_vote_weight_validation = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE * 2))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE * 3))
    .then(produce_block)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))
    .expect(and {
      pending_votes.size() == 3,
      // All validators can vote regardless of stake amount
      validators.get(0).stake == MIN_VALIDATOR_STAKE,
      validators.get(1).stake == MIN_VALIDATOR_STAKE * 2,
      validators.get(2).stake == MIN_VALIDATOR_STAKE * 3
    })
  }
}
