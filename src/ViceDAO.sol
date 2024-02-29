//SPDX-LICENSE-Identifier: MIT
pragma solidity 0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CasinoVice is Ownable {

    IERC20 public viceToken;

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
        mapping(address => bool) voters;
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
    uint256 public quorumVotes;
    uint256 public voteSpan;
    uint256 public minimumVotesForProposal;
    uint256 public minimumVotesForQuorum;

    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 indexed id, address indexed proposer);
    event Voted(uint256 indexed id, address indexed voter, bool vote, uint256 votesFor, uint256 votesAgainst);
    

    constructor(
        address _owner,
        address _viceToken
    ) Ownable(_owner) {
        viceToken = IERC20(_viceToken);
    }

    error NotCopeHolder(address _msgSender);
    error AlreadyVoted(address _voter, uint256 _id);

    modifier isCopeTokenHolder() {
        if(viceToken.balanceOf(msg.sender) == 0) revert NotCopeHolder(msg.sender);
        _;
    }

    function createProposal(
        string memory _title,
        string memory description,
        uint256 _endBlock
    ) public isCopeTokenHolder() {
        // Increment proposal count
        proposalCount++;

        // Create proposal
        Proposal storage _proposal = proposals[proposalCount];
        _proposal.id = proposalCount;
        _proposal.proposer = msg.sender;
        _proposal.title = _title;
        _proposal.description = description;
        _proposal.startBlock = block.number;
        _proposal.endBlock = _endBlock;

        emit ProposalCreated(_proposal.id, _proposal.proposer);
    }

    function voteOnProposal(
        uint256 _id,
        Vote _vote
    ) public isCopeTokenHolder() {
        Proposal storage _proposal = proposals[_id];

        // Check if voter has already voted
        if(_proposal.voters[msg.sender]) revert AlreadyVoted(msg.sender, _id);

        // Update voter status
        _proposal.voters[msg.sender] = true;

        // Update proposal vote count
        if(_vote == Vote.For) {
            _proposal.votesFor++;
            _proposal.votesFor >= minimumVotesForProposal ? _proposal.state = ProposalState.Passed : _proposal.state = ProposalState.Active;
        } else if(_vote == Vote.Against) {
            _proposal.votesAgainst++;
            _proposal.votesAgainst >= minimumVotesForProposal ? _proposal.state = ProposalState.Defeated : _proposal.state = ProposalState.Active;
        }
        emit Voted(_id, msg.sender, _vote == Vote.For, _proposal.votesFor, _proposal.votesAgainst);
    }

    function getProposal(uint256 _id) public view returns(ReturnProposal memory _proposal) {
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

    function getProposalCount() public view returns(uint256 _proposalCount) {
        return proposalCount;
    }

}