//SPDX-LICENSE-Identifier: MIT
pragma solidity 0.8.23;

import {ICopeToken} from "src/interfaces/ICopeToken.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SlotsAtViceCasino is Ownable, ReentrancyGuard {
    ICopeToken public copeToken;

    uint256 public constant HACKATHON_BET_AMOUNT = 0.0001 ether;
    uint256 public constant COPE_TOKEN_REWARD_PER_SPIN = 1 ether;

    // Payout win ods
    uint256 public constant PAYOUT_WIN_FOR_3_SYMBOLS = 0.0001 ether;
    uint256 public constant PAYOUT_WIN_FOR_4_SYMBOLS = 0.001 ether;
    uint256 public constant PAYOUT_WIN_FOR_5_SYMBOLS = 0.002 ether;

    event GamePlayed(address player, uint256 amount, uint256[5] slotsResults, bool isWinner);

    error InsufficientBetAmount();
    error InsufficientBalanceToPayWinner();
    error InsufficientBalance();
    error InsufficientCopeTokenBalance();

    constructor(
        address _owner,
        address _copeToken
    ) Ownable(_owner) {
        copeToken = ICopeToken(_copeToken);
    }
    
    function playSlots() external payable nonReentrant {
        if (msg.value < HACKATHON_BET_AMOUNT) revert InsufficientBetAmount();
        if (address(this).balance < PAYOUT_WIN_FOR_5_SYMBOLS) revert InsufficientBalanceToPayWinner();

        // Simplified RNG game logic
        // DO NOT USE THIS IN PRODUCTION, THIS IS FOR HACKATHON PURPOSES ONLY
        // In a real game, you would want to use something like Chainlink VRF
         uint256[5] memory slotsResults;
        bool win = false;
        uint256 maxConsecutive = 0;
        uint256 currentConsecutive = 1; // Start at 1 to count the first symbol

        // Simplified RNG game logic
        // DO NOT USE THIS IN PRODUCTION, THIS IS FOR HACKATHON PURPOSES ONLY
        // In a real game, you would want to use something like Chainlink VRF
        for (uint i = 0; i < 5; i++) {
            slotsResults[i] = (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, i))) % 6);
            if (i > 0 && slotsResults[i] == slotsResults[i - 1]) {
                currentConsecutive++;
                if (currentConsecutive > maxConsecutive) {
                    maxConsecutive = currentConsecutive;
                }
            } else {
                currentConsecutive = 1; // Reset if no match
            }
        }
        
        win = maxConsecutive >= 3; // Win condition: at least 3 in a row
        
        uint256 payout = 0;
        if (win) {
            if (maxConsecutive == 3) {
                payout = PAYOUT_WIN_FOR_3_SYMBOLS;
            } else if (maxConsecutive == 4) {
                payout = PAYOUT_WIN_FOR_4_SYMBOLS;
            } else if (maxConsecutive == 5) {
                payout = PAYOUT_WIN_FOR_5_SYMBOLS;
            }

            if (payout > 0) {
                payable(msg.sender).transfer(payout);
            }
        }

        // Distribute COPE tokens regardless of win/loss
        copeToken.mint(msg.sender, COPE_TOKEN_REWARD_PER_SPIN);

        emit GamePlayed(msg.sender, msg.value, slotsResults, win);
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