module test_grandpa_supermajority {
  import confiture.* from "../confiture"

  // Test: Exact threshold validation (GRANDPA_THRESHOLD = 5)
  run test_exact_threshold_validation = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator4", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator5", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator6", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator7", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    // Exactly GRANDPA_THRESHOLD votes
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
      pending_votes.filter(v => and {
        v.vote_type == Prevote,
        v.target_number == 1
      }).size() == GRANDPA_THRESHOLD,
      pending_votes.filter(v => and {
        v.vote_type == Precommit,
        v.target_number == 1
      }).size() == GRANDPA_THRESHOLD
    })
  }

  // Test: One vote below threshold (should fail)
  run test_below_threshold_failure = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator4", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator5", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator6", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    // One vote below GRANDPA_THRESHOLD (4 instead of 5)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(0, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Precommit, "block_hash_1", 1))
    .then(finalize_block("block_hash_1", 1))
    .expect(and {
      not(finalized_blocks.contains(1)),
      pending_votes.filter(v => and {
        v.vote_type == Prevote,
        v.target_number == 1
      }).size() == 4,
      pending_votes.filter(v => and {
        v.vote_type == Precommit,
        v.target_number == 1
      }).size() == 4
    })
  }

  // Test: Supermajority with large validator set
  run test_supermajority_large_validator_set = {
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
    .then(register_validator("validator11", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator12", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    // More than threshold votes (8 out of 12 validators)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(5, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(6, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(7, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(0, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(5, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(6, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(7, Precommit, "block_hash_1", 1))
    .then(finalize_block("block_hash_1", 1))
    .expect(and {
      finalized_blocks.contains(1),
      validators.keys().size() == 12,
      pending_votes.filter(v => and {
        v.vote_type == Prevote,
        v.target_number == 1
      }).size() == 8,
      pending_votes.filter(v => and {
        v.vote_type == Precommit,
        v.target_number == 1
      }).size() == 8
    })
  }

  // Test: Split vote scenario (no supermajority)
  run test_split_vote_no_supermajority = {
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
    .then(produce_block)
    .then(produce_block)
    // Split votes between two blocks (4 vs 4, neither reaches threshold)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Prevote, "block_hash_2", 2))
    .then(submit_grandpa_vote(5, Prevote, "block_hash_2", 2))
    .then(submit_grandpa_vote(6, Prevote, "block_hash_2", 2))
    .then(submit_grandpa_vote(7, Prevote, "block_hash_2", 2))
    .then(submit_grandpa_vote(0, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Precommit, "block_hash_2", 2))
    .then(submit_grandpa_vote(5, Precommit, "block_hash_2", 2))
    .then(submit_grandpa_vote(6, Precommit, "block_hash_2", 2))
    .then(submit_grandpa_vote(7, Precommit, "block_hash_2", 2))
    .then(finalize_block("block_hash_1", 1))
    .then(finalize_block("block_hash_2", 2))
    .expect(and {
      // Neither block should finalize due to insufficient votes
      not(finalized_blocks.contains(1)),
      not(finalized_blocks.contains(2)),
      pending_votes.filter(v => v.target_number == 1).size() == 8,
      pending_votes.filter(v => v.target_number == 2).size() == 8
    })
  }

  // Test: Unanimous vote (all validators agree)
  run test_unanimous_vote = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator4", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator5", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator6", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator7", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    // All validators vote for the same block
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(5, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(6, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(0, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(5, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(6, Precommit, "block_hash_1", 1))
    .then(finalize_block("block_hash_1", 1))
    .expect(and {
      finalized_blocks.contains(1),
      validators.keys().size() == 7,
      pending_votes.filter(v => and {
        v.vote_type == Prevote,
        v.target_number == 1
      }).size() == 7,
      pending_votes.filter(v => and {
        v.vote_type == Precommit,
        v.target_number == 1
      }).size() == 7
    })
  }

  // Test: Minimum validator set for threshold
  run test_minimum_validator_set_threshold = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator4", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator5", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    // Exactly minimum validators needed for threshold
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
      validators.keys().size() == 5,
      validators.keys().forall(i => validators.get(i).state == ValidatorActive),
      pending_votes.filter(v => v.target_number == 1).size() == 10  // 5 prevotes + 5 precommits
    })
  }

  // Test: Asymmetric vote distribution (more prevotes than precommits)
  run test_asymmetric_vote_distribution = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator2", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator3", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator4", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator5", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator6", MIN_VALIDATOR_STAKE))
    .then(register_validator("validator7", MIN_VALIDATOR_STAKE))
    .then(produce_block)
    // More prevotes than precommits (7 vs 5)
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(5, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(6, Prevote, "block_hash_1", 1))
    .then(submit_grandpa_vote(0, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Precommit, "block_hash_1", 1))
    .then(finalize_block("block_hash_1", 1))
    .expect(and {
      finalized_blocks.contains(1),
      pending_votes.filter(v => and {
        v.vote_type == Prevote,
        v.target_number == 1
      }).size() == 7,
      pending_votes.filter(v => and {
        v.vote_type == Precommit,
        v.target_number == 1
      }).size() == 5
    })
  }

  // Test: Threshold constants validation
  run test_threshold_constants_validation = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .expect(and {
      GRANDPA_THRESHOLD == 5,
      FINALITY_THRESHOLD == 2,
      GRANDPA_ROUND_DURATION == 30,
      // Verify threshold is reasonable for consensus
      GRANDPA_THRESHOLD > 0,
      FINALITY_THRESHOLD > 0
    })
  }

  // Test: Byzantine fault tolerance (1/3 malicious validators)
  run test_byzantine_fault_tolerance = {
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
    .then(produce_block)
    .then(produce_block)
    // Simulate 1/3 Byzantine validators (3 out of 9) voting maliciously
    .then(submit_grandpa_vote(0, Prevote, "block_hash_1", 1))  // Honest
    .then(submit_grandpa_vote(1, Prevote, "block_hash_1", 1))  // Honest
    .then(submit_grandpa_vote(2, Prevote, "block_hash_1", 1))  // Honest
    .then(submit_grandpa_vote(3, Prevote, "block_hash_1", 1))  // Honest
    .then(submit_grandpa_vote(4, Prevote, "block_hash_1", 1))  // Honest
    .then(submit_grandpa_vote(5, Prevote, "block_hash_1", 1))  // Honest
    .then(submit_grandpa_vote(6, Prevote, "block_hash_2", 2))  // Byzantine
    .then(submit_grandpa_vote(7, Prevote, "block_hash_2", 2))  // Byzantine
    .then(submit_grandpa_vote(8, Prevote, "block_hash_2", 2))  // Byzantine
    .then(submit_grandpa_vote(0, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(1, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(2, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(3, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(4, Precommit, "block_hash_1", 1))
    .then(submit_grandpa_vote(5, Precommit, "block_hash_1", 1))
    .then(finalize_block("block_hash_1", 1))
    .expect(and {
      finalized_blocks.contains(1),
      not(finalized_blocks.contains(2)),
      // Honest majority (6 votes) should prevail over Byzantine minority (3 votes)
      pending_votes.filter(v => and {
        v.vote_type == Prevote,
        v.target_number == 1
      }).size() == 6,
      pending_votes.filter(v => and {
        v.vote_type == Prevote,
        v.target_number == 2
      }).size() == 3
    })
  }
}
