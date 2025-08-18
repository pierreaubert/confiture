// JAM Protocol Specification in Quint (0.7.2)
// Join-Accumulate Machine: A trustless supercomputer combining Polkadot and Ethereum elements
// State of the specs is alpha

module confiture {

  type DataBlob = {
    id: int,
    data: str,
    size: int,
    erasure_coded: bool,
    availability_proof: str
  }

  type DataSegment = {
    blob_id: int,
    segment_index: int,
    data: str,
    proof: str
  }

  type ServiceState = ServiceInactive | ServiceActive | Suspended | Terminated

  type CoreState = Available | Occupied | Disputed
  type WorkItemStatus = WorkPending | InProgress | Refined | Accumulated | WorkFailed

  // Core JAM Service definition with entry points (§2.2 Services)
  type Service = {
    id: int,
    owner: str,
    code_hash: str,
    state: ServiceState,
    balance: int,
    // Service entry points (§2.2.1 Service Entry Points)
    refine_code: str,      // fn refine() - in-core execution
    accumulate_code: str,  // fn accumulate() - on-chain execution
    on_message_code: str   // on_message() - inter-service messaging
  }

  // Work Package - collection of work items for a service (§3.1 Work Packages)
  type WorkPackage = {
    id: int,
    service_id: int,
    work_items: Set[WorkItem],
    authorization: str,
    context: WorkContext,
    status: WorkItemStatus,
    core_assignment: int,
    gas_limit: int,
    gas_consumed: int
  }

  // Work Item - individual unit of work (§3.1.1 Work Items)
  type WorkItem = {
    id: int,
    service_id: int,
    payload: str,
    gas_limit: int,
    status: WorkItemStatus,
    refine_output: str,    // Output from refine phase (§3.2 Refinement)
    accumulate_input: str  // Input to accumulate phase (§3.3 Accumulation)
  }

  // Work Result - output from work package processing (§3.4 Work Results)
  type WorkResult = {
    package_id: int,
    service_id: int,
    core_index: int,
    refined_outputs: Set[str],
    accumulate_data: str,
    gas_used: int,
    success: bool
  }

  // Core - execution environment for work packages (§2.1 Cores)
  type Core = {
    index: int,
    state: CoreState,
    current_package: int,  // Work package ID being processed
    validator_set: Set[str], // Validators assigned to this core (§5.1 Validator Assignment)
    time_allocated: int
  }

  // Work Context - execution context for work packages (§3.1.2 Work Context)
  type WorkContext = {
    block_number: int,
    timestamp: int,
    entropy: str,           // Entropy from §4.3 Entropy Pool
    prior_state_root: str   // State root from previous block
  }

  // JAM Block Header - contains block metadata and commitments (§4.2 Block Header)
  type BlockHeader = {
    parent_hash: str,           // Hash of the parent block (§4.2.1)
    block_number: int,          // Sequential block number (§4.2.2)
    state_root: str,            // Root of the JAM state trie (§4.2.3)
    extrinsics_root: str,       // Root of extrinsics trie (§4.2.4)
    entropy_pool_root: str,     // Current entropy accumulator (§4.3)
    timestamp: int,             // Block timestamp (§4.2.5)
    epoch: int,                 // Current epoch number (§4.2.6)
    winning_tickets: Set[str],  // Winning lottery tickets for this block (§5.2)
    offenders_markers: Set[str], // Markers for validator offenses (§5.3)
    author_index: int,          // Index of the block author (§5.1)
    seal: str                   // Block seal/signature (§4.2.7)
  }

  // JAM Block - complete block structure (§4.2 Block Structure)
  type Block = {
    header: BlockHeader,                        // Block header (§4.2)
    extrinsics: Set[Extrinsic],                // Extrinsics (§4.4)
    guarantees: Set[Guarantee],                // Work guarantees (§5.4)
    assurances: Set[Assurance],                // Availability assurances (§5.5)
    preimages: Set[Preimage],                  // Data preimages (§4.5)
    availability: Set[AvailabilityAttestation] // Availability attestations (§5.6)
  }

  // Extrinsic - external transaction or operation (§4.4 Extrinsics)
  type Extrinsic = {
    id: int,
    extrinsic_type: ExtrinsicType,
    data: str,
    signature: str,
    author: str
  }

  type ExtrinsicType = Transfer | ServiceCallExtrinsic | WorkPackageSubmission | Governance

  // Guarantee - validator guarantee for work package execution (§5.4 Work Guarantees)
  type Guarantee = {
    work_package_hash: str,
    core_index: int,
    validator_index: int,
    signature: str,
    timeslot: int
  }

  // Assurance - assurance of work package availability (§5.5 Availability Assurances)
  type Assurance = {
    work_package_hash: str,
    assurer_index: int,
    signature: str,
    bitfield: str  // Availability bitfield
  }

  // Preimage - data preimage for work packages (§4.5 Data Preimages)
  type Preimage = {
    hash: str,
    data: str,
    length: int
  }

  // Availability Attestation - attestation of data availability (§5.6 Availability Attestations)
  type AvailabilityAttestation = {
    core_index: int,
    validator_index: int,
    availability_bitfield: str,
    signature: str
  }

  // Legacy service call for backward compatibility (§2.3 Service Calls)
  type ServiceCall = {
    caller: str,
    service_id: int,
    method: str,
    gas_limit: int,
    gas_price: int
  }

  // ============================================================================
  // SAFROLE CONSENSUS TYPES (§6 SAFROLE Consensus)
  // ============================================================================

  type ValidatorState = ValidatorActive | ValidatorInactive | Slashed
  type TicketStatus = TicketPending | Winning | Used | Expired

  // Validator entry in the validator set (§6.1 Validator Set)
  type Validator = {
    index: int,
    public_key: str,
    state: ValidatorState,
    stake: int,
    core_assignments: Set[int],     // Cores assigned to this validator
    last_block_authored: int
  }

  // SAFROLE ticket for block production (§6.2 Ticket System)
  type Ticket = {
    id: str,
    validator_index: int,
    slot_number: int,
    status: TicketStatus,
    entropy_input: str,
    signature: str
  }

  // Block seal containing SAFROLE proof (§6.3 Block Sealing)
  type SafroleSeal = {
    ticket_id: str,
    validator_signature: str,
    entropy_proof: str,
    slot_number: int
  }

  // ============================================================================
  // GRANDPA FINALITY TYPES (§7 GRANDPA Finality)
  // ============================================================================

  type VoteType = Prevote | Precommit
  type FinalityState = FinalityPending | Finalized | Conflicted

  // GRANDPA vote for finality (§7.1 GRANDPA Voting)
  type GrandpaVote = {
    voter_index: int,
    vote_type: VoteType,
    target_hash: str,
    target_number: int,
    signature: str,
    round_number: int
  }

  // GRANDPA justification for finalized blocks (§7.2 Finality Justification)
  type FinalityJustification = {
    round_number: int,
    target_hash: str,
    target_number: int,
    prevotes: Set[GrandpaVote],
    precommits: Set[GrandpaVote],
    finality_state: FinalityState
  }

  // ============================================================================
  // PVM (POLKA VIRTUAL MACHINE) TYPES (§8 PVM)
  // ============================================================================

  type PvmInstructionType = Load | Store | Compute | Branch | Call | Return
  type PvmExecutionState = Running | Paused | Completed | PvmFailed | AwaitingCall | OutOfGas

  // PVM program instruction (§8.1 PVM Instructions)
  type PvmInstruction = {
    opcode: PvmInstructionType,
    operands: Set[int],
    gas_cost: int
  }

  // PVM execution context (§8.2 PVM Execution Context)
  type PvmContext = {
    program_counter: int,
    stack: Set[int],
    memory: int -> int,
    gas_remaining: int,
    execution_state: PvmExecutionState,
    return_data: str
  }

  // PVM program for service execution (§8.3 PVM Programs)
  type PvmProgram = {
    bytecode: str,
    instructions: Set[PvmInstruction],
    entry_points: Set[str],        // refine, accumulate, on_message
    gas_limit: int,
    memory_limit: int
  }

  // ============================================================================
  // CRYPTOGRAPHIC PRIMITIVES (§9 Cryptography)
  // ============================================================================

  type HashAlgorithm = Blake2b | Keccak256 | Sha256
  type SignatureScheme = Ed25519 | Sr25519 | Ecdsa

  // Cryptographic hash (§9.1 Hash Functions)
  type Hash = {
    algorithm: HashAlgorithm,
    input: str,
    output: str
  }

  // Digital signature (§9.2 Digital Signatures)
  type Signature = {
    scheme: SignatureScheme,
    public_key: str,
    message: str,
    signature: str,
    valid: bool
  }

  // Merkle tree for data integrity (§9.3 Merkle Trees)
  type MerkleTree = {
    root: str,
    leaves: Set[str],
    proofs: Set[str]
  }

  // ============================================================================
  // Dispute Resolution System types (§12 Disputes)
  // ============================================================================
  type DisputeType = InvalidWorkPackage | InvalidGuarantee | InvalidAssurance | SlashableOffense
  type DisputeStatus = DisputeOpen | DisputeResolved | DisputeRejected | DisputeSlashed

  type Dispute = {
    id: int,
    dispute_type: DisputeType,
    target_validator: str,
    evidence: str,
    status: DisputeStatus,
    initiated_by: str,
    block_number: int,
    resolution_votes: Set[str]
  }

  type SlashingEvent = {
    validator: str,
    amount: int,
    reason: DisputeType,
    block_number: int
  }

  // ============================================================================
  // Scheduling types (§13 Scheduling)
  // ============================================================================
  type WorkPackagePriority = High | Medium | Low
  type SchedulingPolicy = PriorityBased | GasWeighted | StakeWeighted | FIFO

  type ScheduledWorkPackage = {
    package: WorkPackage,
    priority: WorkPackagePriority,
    submission_time: int,
    gas_fee: int,
    submitter_stake: int
  }

  // ============================================================================
  // CoreChains compatibility types (§14 CoreChains)
  // ============================================================================
  type ParachainState = Active | Inactive | Onboarding | Offboarding
  type XcmpMessageType = DownwardMessage | UpwardMessage | HorizontalMessage

  type Parachain = {
    id: int,
    genesis_head: str,
    validation_code: str,
    state: ParachainState,
    lease_period_start: int,
    lease_period_end: int
  }

  type XcmpMessage = {
    id: int,
    message_type: XcmpMessageType,
    source_para: int,
    dest_para: int,
    payload: str,
    processed: bool
  }

  // ============================================================================
  // STATE VARIABLES (§1.3 JAM State)
  // ============================================================================
  // Basic state variables
  var current_block: int
  var services: int -> Service                    // Service registry (§2.2)
  var accounts: str -> int                        // Account balances
  var pending_calls: Set[ServiceCall]             // Pending service calls (§2.3)
  var next_service_id: int

  // Core execution state (§2.1)
  var cores: int -> Core
  var work_packages: int -> WorkPackage           // Work package registry (§3.1)
  var work_results: int -> WorkResult             // Work results (§3.4)
  var pending_work_packages: Set[WorkPackage]
  var next_package_id: int
  var next_work_item_id: int

  // JAM Chain State (§4.1)
  var jam_state_root: str                         // Global state root
  var entropy_pool: str                           // Entropy accumulator (§4.3)
  var validator_assignments: int -> Set[str]      // Core validator assignments (§5.1)

  // Blockchain state (§4.2)
  var blocks: int -> Block                        // Block storage
  var chain_head: int                             // Current chain head
  var current_epoch: int                          // Current epoch (§4.2.6)
  var pending_extrinsics: Set[Extrinsic]          // Extrinsic mempool (§4.4)
  var next_extrinsic_id: int

  // SAFROLE consensus state (§6 SAFROLE)
  var validators: int -> Validator                // Validator registry (§6.1)
  var validator_count: int                        // Total number of validators
  var tickets: str -> Ticket                     // Active tickets (§6.2)
  var pending_tickets: Set[Ticket]               // Tickets awaiting processing
  var current_slot: int                          // Current SAFROLE slot
  var entropy_accumulator: str                   // SAFROLE entropy (§6.4)

  // GRANDPA finality state (§7 GRANDPA)
  var finalized_blocks: Set[int]                 // Finalized block numbers
  var grandpa_round: int                         // Current GRANDPA round
  var pending_votes: Set[GrandpaVote]            // Pending GRANDPA votes
  var finality_justifications: int -> FinalityJustification  // Block justifications

  // PVM execution state (§8 PVM)
  var pvm_programs: int -> PvmProgram            // Service PVM programs
  var pvm_contexts: int -> PvmContext            // Active PVM execution contexts
  var pvm_gas_used: int                          // Total PVM gas consumed

  // Data Availability Layer state (§11 Data Availability)
  var data_blobs: int -> DataBlob                // Stored data blobs
  var data_segments: int -> Set[DataSegment]     // Erasure coded segments
  var next_blob_id: int                          // Next available blob ID
  var availability_threshold: int                // Required availability threshold

  // Dispute Resolution System state (§12 Disputes)
  var disputes: int -> Dispute
  var next_dispute_id: int
  var slashing_events: Set[SlashingEvent]

  // Advanced Scheduling state (§13 Scheduling)
  var scheduled_packages: Set[ScheduledWorkPackage]
  var scheduling_policy: SchedulingPolicy

  // CoreChains compatibility state (§14 CoreChains)
  var parachains: int -> Parachain
  var xcmp_messages: Set[XcmpMessage]
  var next_xcmp_message_id: int

  // ============================================================================
  // CONSTANTS
  // ============================================================================

  // Protocol constants (§1.2 Protocol Parameters)
  pure val MAX_GAS_PER_BLOCK = 15000000           // Maximum gas per block
  pure val MIN_SERVICE_BALANCE = 1000             // Minimum service balance (§2.2)
  pure val TOTAL_CORES = 341                      // JAM protocol specifies 341 cores (§2.1)
  pure val CORE_INDICES = 0.to(TOTAL_CORES - 1)
  pure val MAX_WORK_ITEMS_PER_PACKAGE = 16        // Maximum work items per package (§3.1)
  pure val VALIDATORS = Set("val1", "val2", "val3", "val4", "val5", "val6")  // Simplified validator set (§5.1)

  // SAFROLE constants (§6 SAFROLE Parameters)
  pure val SAFROLE_SLOT_DURATION = 6000           // 6 second slots (§6.2)
  pure val TICKETS_PER_EPOCH = 600                // Tickets issued per epoch (§6.2)
  pure val MIN_VALIDATOR_STAKE = 10000            // Minimum stake for validators (§6.1)
  pure val MAX_VALIDATORS = 1023                  // Maximum validator count (§6.1)
  pure val VALIDATOR_ROTATION_PERIOD = 100       // Epochs between validator rotations (§6.3)

  // GRANDPA constants (§7 GRANDPA Parameters)
  pure val GRANDPA_ROUND_DURATION = 30  // seconds per GRANDPA round (§7.3)
  pure val GRANDPA_THRESHOLD = 5       // minimum votes needed for finalization (§7.2)
  pure val FINALITY_THRESHOLD = 2                // 2/3 supermajority (§7.2)

  // PVM constants (§8 PVM Parameters)
  pure val PVM_MAX_MEMORY = 1048576               // 1MB max memory per program (§8.2)
  pure val PVM_MAX_STACK_SIZE = 1024              // Max stack depth (§8.2)
  pure val PVM_GAS_PER_INSTRUCTION = 1           // Base gas cost per instruction (§8.4)

  // Economic constants (§10 Economics)
  pure val BLOCK_REWARD = 1000                   // Reward for block production (§10.2)

  // ============================================================================
  // HELPER FUNCTIONS
  // ============================================================================

  // Calculate total cost for a caller across a set of calls (§2.3 Service Call Economics)
  pure def total_cost_for_caller(calls: Set[ServiceCall], caller: str): int =
    calls.filter(call => call.caller == caller)
         .fold(0, (acc, call) => acc + call.gas_limit * call.gas_price)

  // Check if a set of calls can be afforded by all callers (§2.3 Service Call Economics)
  pure def calls_affordable(calls: Set[ServiceCall], account_balances: str -> int): bool =
    Set("alice", "bob", "charlie").forall(caller =>
      account_balances.get(caller) >= total_cost_for_caller(calls, caller)
    )

  // JAM-specific helper functions

  // Calculate total gas for work items in a package (§3.1 Work Package Gas)
  pure def package_gas_total(items: Set[WorkItem]): int =
    items.fold(0, (acc, work_item) => acc + work_item.gas_limit)

  // Check if a core is available for assignment (§2.1 Core Availability)
  pure def core_available(core: Core): bool =
    core.state == Available

  // Get available cores (§2.1 Core Management)
  pure def available_cores(core_map: int -> Core): Set[int] =
    CORE_INDICES.filter(i => core_available(core_map.get(i)))

  // Create work context for current block (§3.1.2 Work Context Creation)
  pure def create_work_context(block_num: int, entropy: str, state_root: str): WorkContext =
    { block_number: block_num, timestamp: block_num * 6000, entropy: entropy, prior_state_root: state_root }

  // ============================================================================
  // Create genesis block (§4.2 Genesis Block)
  // ============================================================================
  pure def create_genesis_block(): Block = {
    val genesis_header = {
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
    }
    {
      header: genesis_header,
      extrinsics: Set(),
      guarantees: Set(),
      assurances: Set(),
      preimages: Set(),
      availability: Set()
    }
  }

  // ============================================================================
  // Create block header for new block (§4.2 Block Header Construction)
  // ============================================================================
  pure def create_block_header(parent_hash: str, block_num: int, state_root: str, entropy_root: str, timestamp: int, epoch: int): BlockHeader = {
    parent_hash: parent_hash,
    block_number: block_num,
    state_root: state_root,
    extrinsics_root: "extrinsics_root",
    entropy_pool_root: entropy_root,
    timestamp: timestamp,
    epoch: epoch,
    winning_tickets: Set(),
    offenders_markers: Set(),
    author_index: 0,
    seal: "block_seal"
  }

  // ============================================================================
  // INVARIANTS
  // ============================================================================

  // Account balances should never be negative
  val accounts_non_negative =
    accounts.keys().forall(account => accounts.get(account) >= 0)

  // Service balances should never be negative
  val service_balances_non_negative =
    services.keys().forall(id => services.get(id).balance >= 0)

  // Active services should have minimum balance
  val active_services_funded =
    services.keys().forall(id => {
      val service = services.get(id)
      service.state != ServiceActive or service.balance >= MIN_SERVICE_BALANCE
    })

  // Block numbers should be monotonic
  val blocks_monotonic = current_block >= 0

  // Conservation of funds - total money in system should remain constant
  val total_funds =
    accounts.keys().fold(0, (sum, acc) => sum + accounts.get(acc)) +
    services.keys().fold(0, (sum, id) => sum + services.get(id).balance)

  val funds_conservation = total_funds == 25000  // Initial total: 10000 + 10000 + 5000

  // Total system invariant
  val system_invariant = and {
    accounts_non_negative,
    service_balances_non_negative,
    active_services_funded,
    blocks_monotonic,
    funds_conservation
  }

  // ============================================================================
  // Actions
  // ============================================================================
  action deploy_service(
  	 owner: str,
	 code_hash: str,
	 initial_balance: int,
	 refine_code: str,
	 accumulate_code: str,
	 on_message_code: str
    ): bool = {
    val can_deploy = and {
      accounts.keys().contains(owner),
      accounts.get(owner) >= initial_balance,
      initial_balance >= MIN_SERVICE_BALANCE
    }
    val new_service = {
      id: next_service_id,
      owner: owner,
      code_hash: code_hash,
      state: ServiceActive,
      balance: initial_balance,
      refine_code: refine_code,
      accumulate_code: accumulate_code,
      on_message_code: on_message_code
    }

    all {
      can_deploy,
      // Canonical effect set with actual updates
      current_block' = current_block,
      services' = services.put(next_service_id, new_service),
      accounts' = accounts.setBy(owner, balance => balance - initial_balance),
      pending_calls' = pending_calls,
      next_service_id' = next_service_id + 1,
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

  // Submit a work package for processing
  action submit_work_package(service_id: int, work_items: Set[WorkItem], authorization: str): bool = {
    val service_exists = services.keys().contains(service_id)
    val service = if (service_exists) services.get(service_id) else {
      id: 0, owner: "", code_hash: "", state: ServiceInactive, balance: 0,
      refine_code: "", accumulate_code: "", on_message_code: ""
    }
    val total_gas = package_gas_total(work_items)
    val available_core_set = available_cores(cores)
    val can_submit = and {
      service_exists,
      service.state == ServiceActive,
      work_items.size() <= MAX_WORK_ITEMS_PER_PACKAGE,
      work_items.size() > 0,
      total_gas <= MAX_GAS_PER_BLOCK,
      available_core_set.size() > 0
    }
    val selected_core = if (can_submit and available_core_set.size() > 0) available_core_set.fold(0, (acc, core) => core) else 0
    val work_context = create_work_context(current_block, entropy_pool, jam_state_root)
    val new_package = {
      id: next_package_id,
      service_id: service_id,
      work_items: work_items,
      authorization: authorization,
      context: work_context,
      status: WorkPending,
      core_assignment: selected_core,
      gas_limit: total_gas,
      gas_consumed: 0
    }
    all {
      can_submit,
      // Canonical effect set ordering
      current_block' = current_block,
      services' = services,
      accounts' = accounts,
      pending_calls' = pending_calls,
      next_service_id' = next_service_id,
      cores' = cores.setBy(selected_core, core => { ...core, state: Occupied, current_package: next_package_id }),
      work_packages' = work_packages,
      work_results' = work_results,
      pending_work_packages' = pending_work_packages.union(Set(new_package)),
      next_package_id' = next_package_id + 1,
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

  // Refine phase - execute work items in-core
  action refine_work_package(package_id: int): bool = {
    val package_exists = pending_work_packages.exists(pkg => pkg.id == package_id)
    val work_package = if (package_exists)
      pending_work_packages.filter(pkg => pkg.id == package_id).fold({id: 0, service_id: 0, work_items: Set(), authorization: "", context: {block_number: 0, timestamp: 0, entropy: "", prior_state_root: ""}, status: WorkPending, core_assignment: 0, gas_limit: 0, gas_consumed: 0}, (acc, pkg) => pkg)
      else { id: 0, service_id: 0, work_items: Set(), authorization: "", context: create_work_context(0, "", ""), status: WorkPending, core_assignment: 0, gas_limit: 0, gas_consumed: 0 }
    val service_exists = services.keys().contains(work_package.service_id)
    val service = if (service_exists) services.get(work_package.service_id) else {
      id: 0, owner: "", code_hash: "", state: ServiceInactive, balance: 0,
      refine_code: "", accumulate_code: "", on_message_code: ""
    }
    val can_refine = and {
      package_exists,
      service_exists,
      service.state == ServiceActive,
      cores.get(work_package.core_assignment).state == Occupied
    }
    // Simulate refine execution - in real implementation this would execute service.refine_code
    val refined_items = work_package.work_items.map(wi =>
      { ...wi, status: Refined, refine_output: "refined_output" }
    )
    val refined_package = { ...work_package, work_items: refined_items }
    val work_result = {
      package_id: package_id,
      service_id: work_package.service_id,
      core_index: work_package.core_assignment,
      refined_outputs: refined_items.map(work_item => work_item.refine_output),
      accumulate_data: "accumulate_input",
      gas_used: package_gas_total(work_package.work_items),
      success: true
    }
    all {
      can_refine,
      work_packages' = work_packages.put(package_id, refined_package),
      work_results' = work_results.put(package_id, work_result),
      pending_work_packages' = pending_work_packages.exclude(Set(work_package)),
      // Free the core
      cores' = cores.setBy(work_package.core_assignment, core => { ...core, state: Available, current_package: 0 }),
      // Unchanged state
      current_block' = current_block,
      services' = services,
      accounts' = accounts,
      pending_calls' = pending_calls,
      next_service_id' = next_service_id,
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

  // Accumulate phase - process refined results on-chain
  action accumulate_work_results(result_ids: Set[int]): bool = {
    val results_exist = result_ids.forall(id => work_results.keys().contains(id))
    val can_accumulate = and {
      results_exist,
      result_ids.size() > 0,
      result_ids.size() <= 10  // Limit accumulation batch size
    }
    val results_to_process = result_ids.map(id => work_results.get(id))
    val total_gas_used = results_to_process.fold(0, (acc, result) => acc + result.gas_used)
    // Simulate accumulate execution - in real implementation this would execute service.accumulate_code
    val new_state_root = "state_accumulated"
    all {
      can_accumulate,
      jam_state_root' = new_state_root,
      entropy_pool' = entropy_pool,  // Keep entropy_pool unchanged for now
      // Mark work items as accumulated
      work_packages' = result_ids.fold(work_packages, (packages, result_id) => {
        val result = work_results.get(result_id)
        val package = packages.get(result.package_id)
        val accumulated_items = package.work_items.map(wi =>
          if (result_ids.contains(wi.id)) { ...wi, status: Accumulated }
          else wi
        )
        packages.setBy(result.package_id, pkg => { ...pkg, work_items: accumulated_items })
      }),
      // Unchanged state
      current_block' = current_block,
      services' = services,
      accounts' = accounts,
      pending_calls' = pending_calls,
      next_service_id' = next_service_id,
      cores' = cores,
      work_results' = work_results,
      pending_work_packages' = pending_work_packages,
      next_package_id' = next_package_id,
      next_work_item_id' = next_work_item_id,
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

  // Legacy service call for backward compatibility
  action submit_service_call(caller: str, service_id: int, method: str, gas_limit: int, gas_price: int): bool = {
    val can_call = and {
      accounts.keys().contains(caller),
      services.keys().contains(service_id),
      services.get(service_id).state == ServiceActive,
      accounts.get(caller) >= gas_limit * gas_price
    }
    val new_call = {
      caller: caller,
      service_id: service_id,
      method: method,
      gas_limit: gas_limit,
      gas_price: gas_price
    }

    all {
      can_call,
      pending_calls' = pending_calls.union(Set(new_call)),
      // Unchanged state
      current_block' = current_block,
      services' = services,
      accounts' = accounts,
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

  // Produce a new JAM block with work package processing
  action produce_block: bool = {
    val new_block_number = current_block + 1
    val new_timestamp = new_block_number * 6000  // 6 second block time

    // Process legacy service calls and convert to extrinsics
    val executable_calls = pending_calls.filter(call =>
      calls_affordable(Set(call), accounts)
    )
    val gas_limited_calls = executable_calls.filter(call => call.gas_limit <= MAX_GAS_PER_BLOCK)
    val total_gas = gas_limited_calls.fold(0, (acc, call) => acc + call.gas_limit)
    val final_calls = if (total_gas <= MAX_GAS_PER_BLOCK) gas_limited_calls else Set()

    // Convert service calls to extrinsics
    val service_call_extrinsics = final_calls.map(call => {
      id: next_extrinsic_id,
      extrinsic_type: ServiceCallExtrinsic,
      data: call.method,
      signature: "sig_caller",
      author: call.caller
    })

    // Process pending work packages (refine phase happens automatically)
    val packages_to_refine = pending_work_packages.filter(pkg =>
      cores.get(pkg.core_assignment).state == Occupied
    )

    // Update entropy and state root for new block
    val new_entropy = "entropy_updated"
    val new_state_root = "state_block_updated"
    val parent_hash = if (current_block == 0) "genesis_hash" else "block_hash_prev"

    // Create new block header
    val new_header = create_block_header(parent_hash, new_block_number, new_state_root, new_entropy, new_timestamp, current_epoch)

    // Generate guarantees from work package processing
    val work_guarantees = packages_to_refine.map(pkg => {
      work_package_hash: pkg.authorization,
      core_index: pkg.core_assignment,
      validator_index: if (validator_count > 0) pkg.core_assignment % validator_count else 0,
      signature: "guarantee_signature",
      timeslot: current_slot
    })

    // Generate assurances for work package availability
    val work_assurances = packages_to_refine.map(pkg => {
      work_package_hash: pkg.authorization,
      assurer_index: if (validator_count > 0) (pkg.core_assignment + 1) % validator_count else 0,
      signature: "assurance_signature",
      bitfield: "availability_bitfield"
    })

    // Generate preimages for work package data
    val work_preimages = packages_to_refine.map(pkg => {
      hash: pkg.authorization,
      data: pkg.authorization,
      length: 32  // Fixed length for simplicity
    })

    // Generate availability attestations from validators
    val availability_attestations = cores.keys().filter(core_id => 
      cores.get(core_id).state == Occupied
    ).map(core_id => {
      core_index: core_id,
      validator_index: if (validator_count > 0) core_id % validator_count else 0,  // Assign validator based on core
      availability_bitfield: "available_core",
      signature: "attestation_sig_core"
    })

    // Create new block
    val new_block = {
      header: new_header,
      extrinsics: service_call_extrinsics.union(pending_extrinsics),
      guarantees: work_guarantees,
      assurances: work_assurances,
      preimages: work_preimages,
      availability: availability_attestations
    }

    all {
      current_block' = new_block_number,
      chain_head' = new_block_number,
      blocks' = blocks.put(new_block_number, new_block),
      pending_calls' = pending_calls.exclude(final_calls),
      pending_extrinsics' = Set(),
      next_extrinsic_id' = next_extrinsic_id + service_call_extrinsics.size(),
      accounts' = final_calls.fold(accounts, (acc_map, call) =>
        acc_map.setBy(call.caller, balance => balance - call.gas_limit * call.gas_price)
      ),
      // Update JAM state
      entropy_pool' = new_entropy,
      jam_state_root' = new_state_root,
      // Unchanged state
      services' = services,
      next_service_id' = next_service_id,
      cores' = cores,
      work_packages' = work_packages,
      work_results' = work_results,
      pending_work_packages' = pending_work_packages,
      next_package_id' = next_package_id,
      next_work_item_id' = next_work_item_id,
      validator_assignments' = validator_assignments,
      current_epoch' = current_epoch,
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
    }
  }

  // ============================================================================
  // INITIAL STATE (§1.3 JAM State Initialization)
  // ============================================================================

  action init = all {
    current_block' = 0,
    services' = Map(),
    accounts' = Map("alice" -> 10000, "bob" -> 10000, "charlie" -> 5000),
    pending_calls' = Set(),
    next_service_id' = 1,

    // Initialize cores
    cores' = CORE_INDICES.mapBy(i => {
      index: i,
      state: Available,
      current_package: 0,
      validator_set: Set(),
      time_allocated: 0
    }),

    // Initialize JAM-specific state
    work_packages' = Map(),
    work_results' = Map(),
    pending_work_packages' = Set(),
    next_package_id' = 1,
    next_work_item_id' = 1,

    // Initialize JAM state
    jam_state_root' = "genesis_state",
    entropy_pool' = "initial_entropy",
    validator_assignments' = CORE_INDICES.mapBy(_ => Set()),

    // Initialize blockchain state
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

    // Initialize SAFROLE consensus state
    validators' = Map(),
    validator_count' = 0,
    tickets' = Map(),
    pending_tickets' = Set(),
    current_slot' = 0,
    entropy_accumulator' = "safrole_entropy",

    // Initialize GRANDPA finality state
    finalized_blocks' = Set(0),  // Genesis block is finalized
    grandpa_round' = 0,
    pending_votes' = Set(),
    finality_justifications' = Map(),

    // Initialize PVM execution state
    pvm_programs' = Map(),
    pvm_contexts' = Map(),
    pvm_gas_used' = 0,

    // Initialize Data Availability Layer
    data_blobs' = Map(),
    data_segments' = Map(),
    next_blob_id' = 1,
    availability_threshold' = 2 * TOTAL_CORES / 3,

    // Initialize Dispute Resolution System
    disputes' = Map(),
    next_dispute_id' = 1,
    slashing_events' = Set(),

    // Initialize Advanced Scheduling
    scheduled_packages' = Set(),
    scheduling_policy' = PriorityBased,

    // Initialize CoreChains compatibility
    parachains' = Map(),
    xcmp_messages' = Set(),
    next_xcmp_message_id' = 1
  }

  // Submit an extrinsic to the mempool
  action submit_extrinsic(extrinsic_type: ExtrinsicType, data: str, author: str): bool = {
    val can_submit = accounts.keys().contains(author)
    val new_extrinsic = {
      id: next_extrinsic_id,
      extrinsic_type: extrinsic_type,
      data: data,
      signature: "sig_author",
      author: author
    }

    all {
      can_submit,
      // Canonical effect set with actual updates
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
      pending_extrinsics' = pending_extrinsics.union(Set(new_extrinsic)),
      next_extrinsic_id' = next_extrinsic_id + 1,
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
    }
  }

  // Terminate a service
  action terminate_service(service_id: int, caller: str): bool = {
    val service_exists = services.keys().contains(service_id)
    val service = if (service_exists) services.get(service_id) else {
      id: 0, owner: "", code_hash: "", state: ServiceInactive, balance: 0,
      refine_code: "", accumulate_code: "", on_message_code: ""
    }
    val can_terminate = and {
      service_exists,
      service.owner == caller,
      service.state == ServiceActive
    }
    all {
      can_terminate,
      // Canonical effect set ordering
      current_block' = current_block,
      services' = services.setBy(service_id, s => { ...s, state: Terminated, balance: 0 }),
      accounts' = accounts.setBy(caller, balance => balance + service.balance),
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

  // ============================================================================
  // SAFROLE CONSENSUS ACTIONS (§6 SAFROLE)
  // ============================================================================

  // Register a new validator (§6.1 Validator Registration)
  action register_validator(public_key: str, stake: int): bool = {
    val can_register = and {
      stake >= MIN_VALIDATOR_STAKE,
      validator_count < MAX_VALIDATORS,
      not(validators.keys().exists(i => validators.get(i).public_key == public_key))
    }
    val new_validator = {
      index: validator_count,
      public_key: public_key,
      state: ValidatorActive,
      stake: stake,
      core_assignments: Set(),
      last_block_authored: 0
    }

    all {
      can_register,
      // Canonical effect set with actual updates
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
      validators' = validators.put(validator_count, new_validator),
      validator_count' = validator_count + 1,
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

  // Submit a SAFROLE ticket (§6.2 Ticket Submission)
  action submit_ticket(validator_index: int, slot_number: int, entropy_input: str): bool = {
    val can_submit = and {
      validators.keys().contains(validator_index),
      validators.get(validator_index).state == ValidatorActive,
      slot_number > current_slot
    }
    val ticket_id = "ticket_123"  // Simplified for syntax correctness
    val new_ticket = {
      id: ticket_id,
      validator_index: validator_index,
      slot_number: slot_number,
      status: TicketPending,
      entropy_input: entropy_input,
      signature: "ticket_signature"
    }

    all {
      can_submit,
      // Canonical effect set with actual updates
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
      pending_tickets' = pending_tickets.union(Set(new_ticket)),
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

  // ============================================================================
  // GRANDPA FINALITY ACTIONS (§7 GRANDPA)
  // ============================================================================

  // Submit a GRANDPA vote (§7.1 GRANDPA Voting)
  action submit_grandpa_vote(voter_index: int, vote_type: VoteType, target_hash: str, target_number: int): bool = {
    val can_vote = and {
      validators.keys().contains(voter_index),
      validators.get(voter_index).state == ValidatorActive,
      target_number <= chain_head
    }
    val new_vote = {
      voter_index: voter_index,
      vote_type: vote_type,
      target_hash: target_hash,
      target_number: target_number,
      signature: "grandpa_signature",
      round_number: grandpa_round
    }

    all {
      can_vote,
      pending_votes' = pending_votes.union(Set(new_vote)),
      // Unchanged state (simplified)
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
      grandpa_round' = grandpa_round,
      finality_justifications' = finality_justifications,
      pvm_programs' = pvm_programs,
      pvm_contexts' = pvm_contexts,
      pvm_gas_used' = pvm_gas_used,
      finalized_blocks' = finalized_blocks,
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

  // Finalize a block using GRANDPA (§7.2 GRANDPA Finalization)
  action finalize_block(target_hash: str, target_number: int): bool = {
    val current_round_votes = pending_votes.filter(v => v.round_number == grandpa_round)
    val prevotes = current_round_votes.filter(v => v.vote_type == Prevote and v.target_number == target_number)
    val precommits = current_round_votes.filter(v => v.vote_type == Precommit and v.target_number == target_number)

    val can_finalize = and {
      blocks.keys().contains(target_number),
      blocks.get(target_number).header.parent_hash == target_hash,
      prevotes.size() >= GRANDPA_THRESHOLD,
      precommits.size() >= GRANDPA_THRESHOLD,
      not(finalized_blocks.contains(target_number))
    }

    val justification = {
      round_number: grandpa_round,
      target_hash: target_hash,
      target_number: target_number,
      prevotes: prevotes,
      precommits: precommits,
      finality_state: Finalized
    }

    all {
      can_finalize,
      finalized_blocks' = finalized_blocks.union(Set(target_number)),
      finality_justifications' = finality_justifications.put(target_number, justification),
      grandpa_round' = grandpa_round + 1,
      pending_votes' = Set(),  // Clear votes for next round
      // Unchanged state (simplified)
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

  // ============================================================================
  // PVM EXECUTION ACTIONS (§8 PVM)
  // ============================================================================

  // Deploy a PVM program for a service (§8.3 PVM Program Deployment)
  action deploy_pvm_program(service_id: int, bytecode: str, gas_limit: int): bool = {
    val can_deploy = and {
      services.keys().contains(service_id),
      services.get(service_id).state == ServiceActive,
      gas_limit <= MAX_GAS_PER_BLOCK
    }
    val new_program = {
      bytecode: bytecode,
      instructions: Set(),  // Simplified
      entry_points: Set("refine", "accumulate", "on_message"),
      gas_limit: gas_limit,
      memory_limit: PVM_MAX_MEMORY
    }

    all {
      can_deploy,
      // Canonical effect set with actual updates
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
      pvm_programs' = pvm_programs.put(service_id, new_program),
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

  // ============================================================================
  // DATA AVAILABILITY LAYER ACTIONS (§11 Data Availability)
  // ============================================================================

  // Store data blob with erasure coding
  action store_data_blob(data: str, blob_size: int): bool = {
    val blob_id = next_blob_id
    val new_blob = {
      id: blob_id,
      data: data,
      size: blob_size,
      erasure_coded: true,
      availability_proof: "blob_hash"
    }
    val segments = create_erasure_segments(blob_id, data)
    all {
      // Canonical state effect set ordering
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
      // Actual updates for this action
      data_blobs' = data_blobs.set(blob_id, new_blob),
      data_segments' = data_segments.set(blob_id, segments),
      next_blob_id' = next_blob_id + 1,
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

  // Create erasure coded segments for a data blob
  pure def create_erasure_segments(blob_id: int, data: str): Set[DataSegment] = {
    val segment_count = 4  // Simplified: create 4 segments
    Set(
      { blob_id: blob_id, segment_index: 0, data: "segment_0_data", proof: "segment_0_hash" },
      { blob_id: blob_id, segment_index: 1, data: "segment_1_data", proof: "segment_1_hash" },
      { blob_id: blob_id, segment_index: 2, data: "segment_2_data", proof: "segment_2_hash" },
      { blob_id: blob_id, segment_index: 3, data: "segment_3_data", proof: "segment_3_hash" }
    )
  }

  // Verify data availability for a blob
  def verify_data_availability(blob_id: int): bool = {
    if (data_blobs.keys().contains(blob_id)) {
      val segments = data_segments.get(blob_id)
      segments.size() >= availability_threshold
    } else {
      false
    }
  }

  // ============================================================================
  // COREPLAY SMART CONTRACT ENVIRONMENT (§12 CorePlay)
  // ============================================================================

  type CorePlayActor = {
    id: int,
    address: str,
    code: str,
    state: str,
    paused: bool,
    awaiting_call: bool
  }

  type CorePlayCall = {
    caller_id: int,
    target_id: int,
    method: str,
    data: str,
    gas_limit: int
  }

  // Deploy CorePlay actor (synchronous smart contract)
  action deploy_coreplay_actor(owner: str, code: str, initial_state: str): bool = {
    val actor_id = next_service_id
    val new_actor = {
      id: actor_id,
      address: "actor_address",
      code: code,
      state: initial_state,
      paused: false,
      awaiting_call: false
    }
    all {
      services' = services.put(actor_id, {
        id: actor_id,
        owner: owner,
        code_hash: "actor_code_hash",
        state: ServiceActive,
        balance: 1000,
        refine_code: "main",
        accumulate_code: "accumulate",
        on_message_code: "on_message"
      }),
      next_service_id' = next_service_id + 1,
      // Keep other state unchanged
      current_block' = current_block,
      accounts' = accounts,
      pending_calls' = pending_calls,
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

  // ============================================================================
  // DISPUTE RESOLUTION SYSTEM ACTIONS (§12 Disputes)
  // ============================================================================

  // Initiate a dispute against a validator
  action initiate_dispute(initiator: str, target: str, dispute_type: DisputeType, evidence: str): bool = {
    val dispute_id = next_dispute_id
    val new_dispute = {
      id: dispute_id,
      dispute_type: dispute_type,
      target_validator: target,
      evidence: evidence,
      status: DisputeOpen,
      initiated_by: initiator,
      block_number: current_block,
      resolution_votes: Set()
    }
    all {
      // Canonical effect set with actual updates
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
      disputes' = disputes.set(dispute_id, new_dispute),
      next_dispute_id' = next_dispute_id + 1,
      slashing_events' = slashing_events,
      scheduled_packages' = scheduled_packages,
      scheduling_policy' = scheduling_policy,
      parachains' = parachains,
      xcmp_messages' = xcmp_messages,
      next_xcmp_message_id' = next_xcmp_message_id
    }
  }

  // Vote on dispute resolution
  action vote_on_dispute(dispute_id: int, voter: str, vote_for_slash: bool): bool = {
    val dispute_exists = disputes.keys().contains(dispute_id)
    val current_dispute = disputes.get(dispute_id)
    val can_vote = and {
      dispute_exists,
      current_dispute.status == DisputeOpen,
      validators.keys().exists(i => validators.get(i).public_key == voter)
    }
    if (can_vote) {
      val updated_dispute = {
        id: current_dispute.id,
        dispute_type: current_dispute.dispute_type,
        target_validator: current_dispute.target_validator,
        evidence: current_dispute.evidence,
        status: current_dispute.status,
        initiated_by: current_dispute.initiated_by,
        block_number: current_dispute.block_number,
        resolution_votes: current_dispute.resolution_votes.union(Set(voter))
      }
      val should_slash = updated_dispute.resolution_votes.size() >= 2 * validator_count / 3
      val final_status = if (should_slash and vote_for_slash) DisputeSlashed else
                        if (updated_dispute.resolution_votes.size() >= validator_count / 2) DisputeRejected
                        else DisputeOpen
      all {
        // Canonical effect set with actual updates
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
        disputes' = disputes.set(dispute_id, {
          id: updated_dispute.id,
          dispute_type: updated_dispute.dispute_type,
          target_validator: updated_dispute.target_validator,
          evidence: updated_dispute.evidence,
          status: final_status,
          initiated_by: updated_dispute.initiated_by,
          block_number: updated_dispute.block_number,
          resolution_votes: updated_dispute.resolution_votes
        }),
        next_dispute_id' = next_dispute_id,
        slashing_events' = if (final_status == DisputeSlashed) {
          slashing_events.union(Set({
            validator: current_dispute.target_validator,
            amount: MIN_VALIDATOR_STAKE / 10,
            reason: current_dispute.dispute_type,
            block_number: current_block
          }))
        } else slashing_events,
        scheduled_packages' = scheduled_packages,
        scheduling_policy' = scheduling_policy,
        parachains' = parachains,
        xcmp_messages' = xcmp_messages,
        next_xcmp_message_id' = next_xcmp_message_id
      }
    } else {
      all {
        // Canonical pass-through (no updates)
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
  }

  // ============================================================================
  // WORK PACKAGE SCHEDULING (§13 Scheduling)
  // ============================================================================

  // Submit work package with priority and scheduling info
  action submit_prioritized_work_package(
    service_id: int,
    work_items: Set[WorkItem],
    authorization: str,
    priority: WorkPackagePriority,
    gas_fee: int
  ): bool = {
    val package_id = next_package_id
    val new_package = {
      id: package_id,
      service_id: service_id,
      work_items: work_items,
      authorization: authorization,
      context: create_work_context(current_block, entropy_pool, jam_state_root),
      status: WorkPending,
      core_assignment: 0,
      gas_limit: work_items.fold(0, (acc, work_item) => acc + work_item.gas_limit),
      gas_consumed: 0
    }
    val scheduled_package = {
      package: new_package,
      priority: priority,
      submission_time: current_block,
      gas_fee: gas_fee,
      submitter_stake: if (validators.keys().exists(i => validators.get(i).public_key == authorization)) {
        validators.keys().fold(0, (acc, k) => if (validators.get(k).public_key == authorization) acc + validators.get(k).stake else acc)
      } else 0
    }
    all {
      // Canonical effect set with actual updates
      current_block' = current_block,
      services' = services,
      accounts' = accounts,
      pending_calls' = pending_calls,
      next_service_id' = next_service_id,
      cores' = cores,
      work_packages' = work_packages,
      work_results' = work_results,
      pending_work_packages' = pending_work_packages,
      next_package_id' = next_package_id + 1,
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
      disputes' = disputes,
      next_dispute_id' = next_dispute_id,
      slashing_events' = slashing_events,
      scheduled_packages' = scheduled_packages.union(Set(scheduled_package)),
      scheduling_policy' = scheduling_policy,
      parachains' = parachains,
      xcmp_messages' = xcmp_messages,
      next_xcmp_message_id' = next_xcmp_message_id
    }
  }

  // Get next work package based on scheduling policy
  // Parameterized selector to keep purity in contexts like expect
  pure def select_next_scheduled_package(
    sched: Set[ScheduledWorkPackage],
    policy: SchedulingPolicy
  ): ScheduledWorkPackage = {
    if (sched.size() == 0) {
      // Return dummy package if none available
      {
        package: {
          id: 0, service_id: 0, work_items: Set(), authorization: "",
          context: create_work_context(0, "", ""), status: WorkPending,
          core_assignment: 0, gas_limit: 0, gas_consumed: 0
        },
        priority: Low, submission_time: 0, gas_fee: 0, submitter_stake: 0
      }
    } else if (policy == PriorityBased) {
      // Get highest priority package
      sched.fold(
        sched.fold({package: {id: 0, service_id: 0, work_items: Set(), authorization: "", context: create_work_context(0, "", ""), status: WorkPending, core_assignment: 0, gas_limit: 0, gas_consumed: 0}, priority: Low, submission_time: 0, gas_fee: 0, submitter_stake: 0}, (acc, pkg) => if (priority_score(pkg) > priority_score(acc)) pkg else acc),
        (best, current) => if (priority_score(current) > priority_score(best)) current else best
      )
    } else if (policy == GasWeighted) {
      // Get package with highest gas fee
      sched.fold(
        sched.fold({package: {id: 0, service_id: 0, work_items: Set(), authorization: "", context: create_work_context(0, "", ""), status: WorkPending, core_assignment: 0, gas_limit: 0, gas_consumed: 0}, priority: Low, submission_time: 0, gas_fee: 0, submitter_stake: 0}, (acc, pkg) => if (priority_score(pkg) > priority_score(acc)) pkg else acc),
        (best, current) => if (current.gas_fee > best.gas_fee) current else best
      )
    } else {
      // FIFO - get oldest package
      sched.fold(
        sched.fold({package: {id: 0, service_id: 0, work_items: Set(), authorization: "", context: create_work_context(0, "", ""), status: WorkPending, core_assignment: 0, gas_limit: 0, gas_consumed: 0}, priority: Low, submission_time: 0, gas_fee: 0, submitter_stake: 0}, (acc, pkg) => if (priority_score(pkg) > priority_score(acc)) pkg else acc),
        (best, current) => if (current.submission_time < best.submission_time) current else best
      )
    }
  }

  // Backwards-compatible wrapper that reads state
  pure def get_next_scheduled_package(): ScheduledWorkPackage =
    select_next_scheduled_package(scheduled_packages, scheduling_policy)

  // Calculate priority score for scheduling
  pure def priority_score(scheduled_pkg: ScheduledWorkPackage): int = {
    val base_score = if (scheduled_pkg.priority == High) 100
                    else if (scheduled_pkg.priority == Medium) 50
                    else 10
    val gas_bonus = scheduled_pkg.gas_fee / 1000
    val stake_bonus = scheduled_pkg.submitter_stake / 10000
    base_score + gas_bonus + stake_bonus
  }

  // ============================================================================
  // CORECHAINS SERVICE - POLKADOT COMPATIBILITY (§14 CoreChains)
  // ============================================================================

  // Deploy parachain as JAM service (backward compatibility)
  action deploy_parachain(
    para_id: int,
    genesis_head: str,
    validation_code: str,
    lease_start: int,
    lease_end: int
  ): bool = {
    val new_parachain = {
      id: para_id,
      genesis_head: genesis_head,
      validation_code: validation_code,
      state: Onboarding,
      lease_period_start: lease_start,
      lease_period_end: lease_end
    }
    // Deploy as regular JAM service with CoreChains wrapper
    all {
      parachains' = parachains.set(para_id, new_parachain),
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
      xcmp_messages' = xcmp_messages,
      next_xcmp_message_id' = next_xcmp_message_id
    }
  }

  // Send XCMP message between parachains
  action send_xcmp_message(
    source_para: int,
    dest_para: int,
    message_type: XcmpMessageType,
    payload: str
  ): bool = {
    val message_id = next_xcmp_message_id
    val new_message = {
      id: message_id,
      message_type: message_type,
      source_para: source_para,
      dest_para: dest_para,
      payload: payload,
      processed: false
    }
    all {
      xcmp_messages' = xcmp_messages.union(Set(new_message)),
      next_xcmp_message_id' = next_xcmp_message_id + 1,
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
      parachains' = parachains
    }
  }

  // ============================================================================
  // CRYPTOGRAPHIC PRIMITIVES ACTIONS (§9 Cryptography)
  // ============================================================================

  // Compute cryptographic hash (§9.1 Hashing Functions)
  pure def compute_hash(algorithm: HashAlgorithm, input: str): str =
    if (algorithm == Blake2b) {
      "blake2b_hash"
    } else if (algorithm == Keccak256) {
      "keccak256_hash"
    } else {
      "sha256_hash"
    }

  // Verify digital signature (§9.2 Digital Signatures)
  pure def verify_signature(scheme: SignatureScheme, public_key: str, message: str, signature: str): bool =
    and {
      public_key != "",
      message != "",
      signature != "",
      // Simplified verification - in real implementation would use cryptographic verification
      signature == "sig_valid"
    }

  // Build Merkle tree proof (§9.3 Merkle Trees)
  pure def build_merkle_proof(leaves: Set[str], target_leaf: str): Set[str] =
    if (leaves.contains(target_leaf)) {
      Set("merkle_proof_element")
    } else {
      Set()
    }

  // Hash state root for block (§4.2.3 State Root)
  pure def compute_state_root(services_state: int -> Service, accounts_state: str -> int): str = {
    val services_hash = compute_hash(Blake2b, "services_state")
    val accounts_hash = compute_hash(Blake2b, "accounts_state")
    compute_hash(Blake2b, "combined_state")
  }

  // ============================================================================
  // VALIDATOR ROTATION AND ASSIGNMENT (§6.3 Validator Management)
  // ============================================================================

  // Assign validators to cores for an epoch (§6.3.1 Core Assignment)
  action assign_validators_to_cores(): bool = {
    val active_validators = validators.keys().filter(i => validators.get(i).state == ValidatorActive)
    val can_assign = active_validators.size() >= TOTAL_CORES

    val new_assignments = if (can_assign) {
      CORE_INDICES.mapBy(core_id => {
        val assigned_validators = active_validators.filter(v => v % TOTAL_CORES == core_id)
        assigned_validators.fold(Set(), (acc, v) => acc.union(Set(validators.get(v).public_key)))
      })
    } else {
      validator_assignments
    }

    all {
      can_assign,
      // Canonical effect set with updates
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
      validator_assignments' = new_assignments,
      blocks' = blocks,
      chain_head' = chain_head,
      current_epoch' = current_epoch,
      pending_extrinsics' = pending_extrinsics,
      next_extrinsic_id' = next_extrinsic_id,
      validators' = validators.keys().mapBy(i => {
        val validator = validators.get(i)
        val assigned_cores = CORE_INDICES.filter(core_id =>
          new_assignments.get(core_id).contains(validator.public_key)
        )
        { ...validator, core_assignments: assigned_cores }
      }),
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

  // Rotate validator set for new epoch (§6.3.2 Validator Rotation)
  action rotate_validator_set(): bool = {
    val can_rotate = current_epoch % VALIDATOR_ROTATION_PERIOD == 0

    val updated_validators = if (can_rotate) {
      validators.keys().mapBy(i => {
        val validator = validators.get(i)
        val new_state = if (validator.state == Slashed) {
          ValidatorInactive  // Remove slashed validators
        } else {
          validator.state
        }
        { ...validator, state: new_state, core_assignments: Set() }
      })
    } else {
      validators
    }

    all {
      can_rotate,
      // Canonical effect set with updates
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
      validator_assignments' = CORE_INDICES.mapBy(_ => Set()),
      blocks' = blocks,
      chain_head' = chain_head,
      current_epoch' = current_epoch + 1,
      pending_extrinsics' = pending_extrinsics,
      next_extrinsic_id' = next_extrinsic_id,
      validators' = updated_validators,
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

  // ==========================================================================
  // ECONOMIC MODELS (§10 Economics)
  // ==========================================================================

  // Force slash validator (§10.3 Validator Slashing)
  action force_slash_validator(validator_index: int): bool = {
    val can_slash = validators.keys().contains(validator_index)
    val updated_validator = if (can_slash) {
      val validator = validators.get(validator_index)
      { ...validator, state: Slashed }
    } else {
      validators.get(validator_index)
    }

    all {
      can_slash,
      validators' = validators.put(validator_index, updated_validator),
      // Unchanged state (simplified)
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
    }
  }

  // Charge gas for operation (§10.1 Gas Model)
  action charge_gas(amount: int): bool = {
    val can_charge = pvm_gas_used + amount <= MAX_GAS_PER_BLOCK
    all {
      can_charge,
      pvm_gas_used' = pvm_gas_used + amount,
      // Unchanged state (simplified)
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

  // Distribute block rewards to validators (§10.2 Reward Distribution)
  action distribute_rewards(block_author: int, reward_amount: int): bool = {
    val can_distribute = and {
      validators.keys().contains(block_author),
      validators.get(block_author).state == ValidatorActive,
      reward_amount > 0
    }

    val updated_validator = if (can_distribute) {
      val validator = validators.get(block_author)
      { ...validator, stake: validator.stake + reward_amount }
    } else {
      validators.get(block_author)
    }

    all {
      can_distribute,
      // Canonical full effect set ordering
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
      validators' = validators.put(block_author, updated_validator),
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

  // ============================================================================
  // SYSTEM STEP
  // ============================================================================

  action step: bool = any {
    // Service deployment
    all {
      nondet caller = accounts.keys().oneOf()
      deploy_service(caller, "code_hash", 1000, "refine_code", "accumulate_code", "on_message_code")
    },
    // Legacy service call
    all {
      services.keys().size() > 0,
      nondet caller = accounts.keys().oneOf()
      nondet service_id = services.keys().oneOf()
      nondet gas_limit = 1.to(100).oneOf()
      nondet gas_price = 1.to(10).oneOf()
      submit_service_call(caller, service_id, "call_data", gas_limit, gas_price)
    },
    // Work package submission
    all {
      services.keys().size() > 0,
      nondet service_id = services.keys().oneOf()
      nondet gas_limit = 10.to(100).oneOf()
      val work_item = {
        id: next_work_item_id,
        service_id: service_id,
        payload: "payload",
        gas_limit: gas_limit,
        status: WorkPending,
        refine_output: "",
        accumulate_input: ""
      }
      val work_items = Set(work_item)
      submit_work_package(service_id, work_items, "auth_hash")
    },
    // Work package refinement
    all {
      work_packages.keys().size() > 0,
      nondet package_id = work_packages.keys().oneOf()
      refine_work_package(package_id)
    },
    // Work result accumulation
    all {
      val available_results = work_results.keys().filter(id =>
        work_results.get(id).success == true
      )
      all {
        available_results.size() > 0,
        nondet result_id = available_results.oneOf()
        accumulate_work_results(Set(result_id))
      }
    },
    // Extrinsic submission
    all {
      nondet caller = accounts.keys().oneOf()
      nondet extrinsic_type = Set(Transfer, Governance).oneOf()
      submit_extrinsic(extrinsic_type, "extrinsic_data", caller)
    },
    // Block production
    produce_block,
    // Service termination
    all {
      services.keys().size() > 0,
      nondet caller = accounts.keys().oneOf()
      nondet service_id = services.keys().oneOf()
      terminate_service(service_id, caller)
    },
    // SAFROLE validator registration
    all {
      nondet public_key = Set("validator1", "validator2", "validator3").oneOf()
      nondet stake = Set(MIN_VALIDATOR_STAKE, MIN_VALIDATOR_STAKE + 1000).oneOf()
      register_validator(public_key, stake)
    },
    // SAFROLE ticket submission
    all {
      validators.keys().size() > 0,
      nondet validator_index = validators.keys().oneOf()
      nondet slot_number = Set(current_slot + 1, current_slot + 2).oneOf()
      submit_ticket(validator_index, slot_number, "entropy_input")
    },
    // GRANDPA voting
    all {
      validators.keys().size() > 0,
      nondet voter_index = validators.keys().oneOf()
      nondet vote_type = Set(Prevote, Precommit).oneOf()
      nondet target_number = Set(0, chain_head).oneOf()
      submit_grandpa_vote(voter_index, vote_type, "block_hash", target_number)
    },
    // PVM program deployment
    all {
      services.keys().size() > 0,
      nondet service_id = services.keys().oneOf()
      deploy_pvm_program(service_id, "pvm_bytecode", 1000)
    },
    // GRANDPA block finalization
    all {
      blocks.keys().size() > 1,  // Need at least genesis + 1 block
      chain_head > 0,
      not(finalized_blocks.contains(chain_head)),
      finalize_block("parent_hash", chain_head)
    },
    // Validator assignment to cores
    all {
      validators.keys().size() >= TOTAL_CORES,
      assign_validators_to_cores
    },
    // Validator set rotation
    all {
      current_epoch % VALIDATOR_ROTATION_PERIOD == 0,
      rotate_validator_set
    },
    // Gas charging for operations
    all {
      nondet gas_amount = Set(100, 500, 1000).oneOf()
      charge_gas(gas_amount)
    },
    // Block reward distribution
    all {
      validators.keys().size() > 0,
      nondet block_author = validators.keys().oneOf()
      nondet reward = Set(BLOCK_REWARD, BLOCK_REWARD / 2).oneOf()
      distribute_rewards(block_author, reward)
    }
  }

}



