// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ViceCasinoDAO is Ownable {
    IERC20 public copeToken;

    enum ProposalState {
        Pending,
        Active,
        Defeated,
        Passed
    }

    enum Vote {
        Against,
        For,
        Abstain
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startBlock;
        uint256 endBlock;
        ProposalState state;
        mapping(address => uint256) voters;
    }

    struct ReturnProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startBlock;
        uint256 endBlock;
        ProposalState state;
    }

    

    uint256 public proposalCount;
    uint256 public minimumVotesForQuorum;

    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 indexed id, address indexed proposer);
    event Voted(uint256 indexed id, address indexed voter, Vote vote, uint256 votesFor, uint256 votesAgainst);
    event ProposalStateUpdated(uint256 indexed id, ProposalState newState);

    error NotCopeHolder(address _msgSender);
    error AlreadyVoted(address _voter, uint256 _id);
    error InvalidProposalState(uint256 _id, ProposalState state);
    error InvalidEndBlockForVoting(uint256 _id, uint256 endBlock);
    error VotingPeriodOver(uint256 _id);

    modifier isCopeTokenHolder() {
        if(copeToken.balanceOf(msg.sender) == 0) revert NotCopeHolder(msg.sender);
        _;
    }

    constructor(
        address _owner,
        address _copeToken
    ) Ownable(_owner) {
        copeToken = IERC20(_copeToken);
    }

    function createProposal(string memory _title, string memory _description, uint256 _endBlock) public isCopeTokenHolder {
        // Ensure the end block is in the future by 5760 block close to (24Hrs)
        if (block.number + 5760 >= _endBlock) revert InvalidEndBlockForVoting(proposalCount, _endBlock);

        proposalCount++;
        Proposal storage proposal = proposals[proposalCount];
        proposal.id = proposalCount;
        proposal.proposer = msg.sender;
        proposal.title = _title;
        proposal.description = _description;
        proposal.startBlock = block.number;
        proposal.endBlock = _endBlock;
        proposal.state = ProposalState.Active;

        emit ProposalCreated(proposal.id, proposal.proposer);
    }

    function voteOnProposal(uint256 _id, Vote _vote) public isCopeTokenHolder {
        Proposal storage proposal = proposals[_id];

        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.number <= proposal.endBlock, "Voting period has ended");
        require(proposal.voters[msg.sender] == 0, "Already voted");

        uint256 votingPower = copeToken.balanceOf(msg.sender);
        proposal.voters[msg.sender] = votingPower;

        if (_vote == Vote.For) {
            proposal.votesFor += votingPower;
        } else if (_vote == Vote.Against) {
            proposal.votesAgainst += votingPower;
        } // Abstain does not affect vote counts

        emit Voted(_id, msg.sender, _vote, proposal.votesFor, proposal.votesAgainst);

        // Check if we can conclude the vote immediately after voting
        _updateProposalState(_id);
    }

    function finalizeProposal(uint256 _id) public {
        _updateProposalState(_id);
    }

    function _updateProposalState(uint256 _id) internal {
        Proposal storage proposal = proposals[_id];

        require(proposal.state == ProposalState.Active, "Proposal is not active");
        if (block.number > proposal.endBlock) {
            if ((proposal.votesFor + proposal.votesAgainst >= minimumVotesForQuorum) && (proposal.votesFor > proposal.votesAgainst)) {
                proposal.state = ProposalState.Passed;
            } else {
                proposal.state = ProposalState.Defeated;
            }
            emit ProposalStateUpdated(_id, proposal.state);
        }
    }

    function getProposal(uint256 _id) public view returns (ReturnProposal memory) {
        Proposal storage proposal = proposals[_id];
        return ReturnProposal(
            proposal.id,
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.startBlock,
            proposal.endBlock,
            proposal.state
        );
    }

    function getProposalCount() public view returns (uint256) {
        return proposalCount;
    }

    function hasVotedOnProposal(uint256 _id, address _voter) public view returns (bool) {
        return proposals[_id].voters[_voter] > 0;
    }
}
