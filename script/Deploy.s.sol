// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {CopeToken} from "src/CopeToken.sol";
import {ViceCasinoDAO} from "src/ViceCasinoDAO.sol";
import {SlotsAtViceCasino} from "src/SlotsGame.sol";

contract DeployScript is Script {
    function run() external {
        

        address deployer = 0x289f0A29071a4fDf92F54FB8D580377dA94491d5;
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
            // Deploy CopeToken
            CopeToken copeToken = new CopeToken("CopeToken", "COPE", deployer);
            console2.logString("CopeToken deployed at: ");
            console2.logAddress(address(copeToken));

            // Deploy ViceCasinoDAO
            ViceCasinoDAO viceCasinoDAO = new ViceCasinoDAO(deployer, address(copeToken));
            console2.logString("ViceCasinoDAO deployed at: ");
            console2.logAddress(address(viceCasinoDAO));

            // Deploy SlotsAtViceCasino
            SlotsAtViceCasino slotsAtViceCasino = new SlotsAtViceCasino(deployer, address(copeToken));
            console2.logString("SlotsAtViceCasino deployed at: ");
            console2.logAddress(address(slotsAtViceCasino));


            // set slot machine as the owner of the CopeToken
            copeToken.transferOwnership(address(slotsAtViceCasino));
            console2.logString("CopeToken owner set to: ");
            console2.logAddress(address(slotsAtViceCasino));

            console2.logString("CopeToken owner: ");
            console2.logAddress(copeToken.owner());
        vm.stopBroadcast();
    }
}


/*
forge script script/Deploy.s.sol:DeployScript --rpc-url $SEPOLIA_RPC_URL --verify --broadcast
*/