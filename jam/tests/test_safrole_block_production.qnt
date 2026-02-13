module test_safrole_block_production {
  import confiture.* from "../confiture"

  // Test: Block production with winning ticket
  run test_block_production_with_ticket = {
    init
    .then(register_validator("validator1", MIN_VALIDATOR_STAKE))
    .then(submit_ticket(0, state_safrole.current_slot + 1))
    .then(all {
      // Mark ticket as winning and produce block
      nondet winning_ticket = state_safrole.tickets.oneOf()
      val updated_winning_ticket = { ...winning_ticket, status: Winning }
      state_safrole' = { ...state_safrole, 
        tickets: state_safrole.tickets.exclude(Set(winning_ticket)).union(Set(updated_winning_ticket)),
        validators: state_safrole.validators.setBy(0, v => { ...v, last_block_authored: state_basic.current_block + 1 })
      },
      state_basic' = { ...state_basic, current_block: state_basic.current_block + 1 },
      state_blockchain' = { ...state_blockchain, 
        chain_head: state_basic.current_block + 1,
        blocks: state_blockchain.blocks.put(state_basic.current_block + 1, {
          header: {
            parent_hash: "parent_hash",
            block_number: state_basic.current_block + 1,
            state_root: state_chain.jam_state_root,
            extrinsics_root: "extrinsics_root",
            entropy_pool_root: state_chain.entropy_pool,
            timestamp: (state_basic.current_block + 1) * SAFROLE_SLOT_DURATION,
            epoch: state_blockchain.current_epoch,
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
        })
      },
      // Keep other state unchanged
      state_core' = state_core,
      state_chain' = state_chain,
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    })
    .expect(and {
      state_basic.current_block == 1,
      state_blockchain.chain_head == 1,
      state_blockchain.blocks.keys().contains(1),
      state_safrole.validators.get(0).last_block_authored == 1,
      state_safrole.tickets.exists(ticket => ticket.status == Winning)
    })
  }
}