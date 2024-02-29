//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CopeToken is ERC20, Ownable {

    uint256 public maxSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        uint256 _initialSupply,
        uint256 _maxSupply
    )
        ERC20(_name, _symbol)
        Ownable(_owner)
    {
        maxSupply = _maxSupply;
        _mint(_owner, _initialSupply);
        _transfer(_msgSender(), _owner, _initialSupply);
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "CopeToken: max supply exceeded");
        _mint(_to, _amount);
    }
}
