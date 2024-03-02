//SPDX-LICENSE-Identifier: MIT
pragma solidity 0.8.23;


import "chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "chainlink/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

import {ICopeToken} from "src/interfaces/ICopeToken.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SlotsAtViceCasino is Ownable, VRFConsumerBaseV2, ReentrancyGuard {
    ICopeToken public copeToken;
    
    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }

    uint256 public constant HACKATHON_BET_AMOUNT = 0.0001 ether;
    uint256 public constant COPE_TOKEN_REWARD_PER_SPIN = 1 ether;

    // Payout win ods
    uint256 public constant PAYOUT_WIN_FOR_3_SYMBOLS = 0.0001 ether;
    uint256 public constant PAYOUT_WIN_FOR_4_SYMBOLS = 0.001 ether;
    uint256 public constant PAYOUT_WIN_FOR_5_SYMBOLS = 0.002 ether;

    // Chainlink VRF Vars
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 public s_subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 250000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 5; // Number of random values to request
    uint256[] public s_randomWords;
    uint256 public s_requestId;

    mapping(uint256 => address) private requestToPlayer;

    event GamePlayed(address player, uint256 amount, uint256[5] slotsResults, bool isWinner);
    event RequestSent(uint256 requestId, uint32 numWords);


    error InsufficientBetAmount();
    error InsufficientBalanceToPayWinner();
    error InsufficientBalance();
    error InsufficientCopeTokenBalance();

    constructor(
        address _vrfCoordinator,
        address _owner,
        address _copeToken,
        bytes32 _keyHash,
        uint64 _subscriptionId
    )   VRFConsumerBaseV2(_vrfCoordinator)
        Ownable(_owner) 
    {
        copeToken = ICopeToken(_copeToken);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
    }
    
    function playSlots() external payable nonReentrant returns (uint256 requestId) {
        if (msg.value < HACKATHON_BET_AMOUNT) revert InsufficientBetAmount();
        if (address(this).balance < PAYOUT_WIN_FOR_5_SYMBOLS) revert InsufficientBalanceToPayWinner();

        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords            
        );
        
        requestToPlayer[s_requestId] = msg.sender; // Map request ID to the player
        // Distribute COPE tokens regardless of win/loss
        copeToken.mint(msg.sender, COPE_TOKEN_REWARD_PER_SPIN);

        emit RequestSent(s_requestId, numWords);
        return s_requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        s_randomWords = randomWords;
        uint256[5] memory slotsResults;
        bool win = false;
        uint256 maxConsecutive = 0;
        uint256 currentConsecutive = 1;
        
        // Artificially increase the frequency of a particular symbol in the third slot
        // For example, if we want to increase the chance of symbol '5' appearing in the third slot
        randomWords[2] = (randomWords[2] % 5) + 1; // Adjust the range if you want specific symbols to appear more frequently

        for (uint256 i = 0; i < 5; i++) {
            slotsResults[i] = randomWords[i] % 6; // Remainder will always be between 0 and 5, inclusive
            if (i > 0 && slotsResults[i] == slotsResults[i - 1]) {
                currentConsecutive++;
                if (currentConsecutive > maxConsecutive) {
                    maxConsecutive = currentConsecutive;
                }
            } else {
                currentConsecutive = 1; // Reset consecutive count for different symbols
            }
        }

        win = maxConsecutive >= 3;

        uint256 payout = 0;
        if (win) {
            if (maxConsecutive == 3) payout = PAYOUT_WIN_FOR_3_SYMBOLS;
            else if (maxConsecutive == 4) payout = PAYOUT_WIN_FOR_4_SYMBOLS;
            else if (maxConsecutive == 5) payout = PAYOUT_WIN_FOR_5_SYMBOLS;

            if (payout > 0) {
                payable(requestToPlayer[requestId]).transfer(payout); // Award to the correct player from request id to address mapping
            }
        }

        emit GamePlayed(requestToPlayer[requestId], msg.value, slotsResults, win);
    }


    function withdrawCopeToken(uint256 _amount) external onlyOwner {
        copeToken.transfer(owner(), _amount);
    }

    function withdrawEther() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance <= 0) revert InsufficientBalance();
        payable(owner()).transfer(balance);
    }

    function depositEther() external payable {
        if (msg.value <= 0) revert InsufficientBalance();
    }

    // Allow the contract to receive Ether
    receive() external payable {}
}