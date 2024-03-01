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
    uint256 public constant PAYOUT_WIN_FOR_5_SYMBOLS = 0.001 ether;

    event GamePlayed(address player, uint256 amount, uint256[5] slotsResults);
    event GameWon(address winner, uint256 amount);

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
        uint256 matchCount = 1; // Init match count

        // Init True varable
        bool win = true; // Assume win, prove otherwise
        for (uint i = 0; i < 5; i++) {
            slotsResults[i] = (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, i))) % 6) + 1;
            if (i > 0 && slotsResults[i] != slotsResults[i - 1]) {
                win = false;
            } else if (i > 0) {
                matchCount++;
            }
        }
        
        uint256 payout = 0;
        if (matchCount == 3) {
            payout = PAYOUT_WIN_FOR_3_SYMBOLS;
        } else if (matchCount == 4) {
            payout = PAYOUT_WIN_FOR_4_SYMBOLS;
        } else if (matchCount == 5) {
            payout = PAYOUT_WIN_FOR_5_SYMBOLS;
        }
        
        if (payout > 0) {
            payable(msg.sender).transfer(payout);
            emit GameWon(msg.sender, payout);
        }
        
        // Distribute COPE tokens regardless of win/loss
        copeToken.mint(msg.sender, COPE_TOKEN_REWARD_PER_SPIN);

        emit GamePlayed(msg.sender, msg.value, slotsResults);
    }


    function withdrawCopeToken(uint256 _amount) external onlyOwner {
        copeToken.transfer(owner(), _amount);
    }

    function withdrawEther() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance <= 0) revert InsufficientBalance();
        payable(owner()).transfer(balance);
    }

    // Allow the contract to receive Ether
    receive() external payable {}
}