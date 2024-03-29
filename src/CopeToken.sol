//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CopeToken is ERC20, Ownable {
    constructor(
        string memory _name,
        string memory _symbol,
        address _owner
    )
        ERC20(_name, _symbol)
        Ownable(_owner)
    {
        _transferOwnership(_owner);
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}


