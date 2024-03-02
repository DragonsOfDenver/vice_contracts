// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {CopeToken} from "src/CopeToken.sol";
import {ViceCasinoDAO} from "src/ViceCasinoDAO.sol";
import {SlotsAtViceCasino} from "src/SlotsGame.sol";

contract DeployScript is Script {
    function run() external {
        
        address sepoliaCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
        bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
        uint64 subscriptionId = 9859;
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
            SlotsAtViceCasino slotsAtViceCasino = new SlotsAtViceCasino(
                sepoliaCoordinator,
                deployer,
                address(copeToken),
                keyHash,
                subscriptionId
            );
            console2.logString("SlotsAtViceCasino deployed at: ");
            console2.logAddress(address(slotsAtViceCasino));


            // set slot machine as the owner of the CopeToken
            copeToken.transferOwnership(address(slotsAtViceCasino));
            console2.logString("CopeToken owner set to: ");
            console2.logAddress(address(slotsAtViceCasino));

            console2.logString("CopeToken owner: ");
            console2.logAddress(copeToken.owner());

            // deposit 0.05 ether into slots game
            slotsAtViceCasino.depositEther{ value: 0.05 ether }();

        vm.stopBroadcast();
    }
}


/*
forge script script/Deploy.s.sol:DeployScript --rpc-url $SEPOLIA_RPC_URL --verify --broadcast
*/