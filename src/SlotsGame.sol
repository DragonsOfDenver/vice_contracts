//SPDX-LICENSE-Identifier: MIT
pragma solidity 0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract SlotsAtViceCasino is Ownable {

    struct slotSpin {
        uint256 id;
        address player;
        // WHAT ELSE!!!!!
    }    

    constructor(address _owner) Ownable(_owner) {}


    


}