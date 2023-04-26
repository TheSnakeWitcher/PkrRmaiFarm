//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
pragma abicoder v2;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "./TestUtil.t.sol";

import "src/PkrRmaiFarm.sol";

contract PkrRmaiFarmTest is Test, TestUtil {
    PkrRmaiFarm testContract;
    address testUser1 = vm.addr(1);
    address testUser2 = makeAddr("jesus");
    address testUser3 =
        address(
            0x000000000000000000000000a8ab31f2f71a854c6cc73e23e01cec6c1fe552ce
        );

    function setUpForks() private {
        // _localFork = vm.createFork(vm.rpcUrl("local"));
        // _ethereumFork = vm.createFork(vm.rpcUrl("ethereum"));
        // _goerliFork = vm.createFork(vm.rpcUrl("goerli"));
        // _polygonFork = vm.createFork(vm.rpcUrl("polygon"));
        // _mumbaiFork = vm.createFork(vm.rpcUrl("mumbai"));
        // _avalancheFork = vm.createFork(vm.rpcUrl("avalanche"));
        // _fujiFork = vm.createFork(vm.rpcUrl("fuji"));
        _bscFork = vm.createFork(vm.rpcUrl("bsc"));
        // _bsctFork = vm.createFork(vm.rpcUrl("bsct"));
    }

    function setUp() public {
        setUpForks();
        // vm.selectFork(_localFork);
        vm.selectFork(_bscFork);
        testContract = new PkrRmaiFarm();
    }

    function testBalance() public view {
        uint256 pkrBalance1 = testContract.PKR().balanceOf(testUser1);
        uint256 pkrBalance2 = testContract.PKR().balanceOf(testUser2);
        uint256 pkrBalance3 = testContract.PKR().balanceOf(testUser3);
        // uint256 rmaiBalance = testContract.RMAI().balanceOf(testUser1);
        // uint256 maticBalance = testContract.MATIC().balanceOf(testUser1);
        console.log("pkrBalance: ", pkrBalance1);
        console.log("pkrBalance: ", pkrBalance2);
        console.log("pkrBalance: ", pkrBalance3);
        // console.log("rmaiBalance: ", rmaiBalance);
        // console.log("maticBalance: ", maticBalance);
    }

    function testFork(uint256 _forkId) private {
        vm.selectFork(_forkId);
        console.log("active fork id: ", vm.activeFork());
        console.log("block number: ", block.number);
        console.log("chain id: ", block.chainid);
        console.log("timestamp: ", block.timestamp);
        console.log("gas price: ", tx.gasprice);
    }

    function testLocalFork() public {
        testFork(_localFork);
    }

    function testOwner() public {
        assertEq(testContract.owner(), DEPLOYER_ADDRESS);
    }

    function testFailOwner() public {
        assertEq(testContract.owner(), address(0));
    }

    function testFailOwnerFuzzy(address arg) public {
        assertEq(testContract.owner(), arg);
    }

    function testPoolDeposit() public {
        testContract.poolDeposit(testUser1, testUser1, testUser1, 12);
    }

    // function testFarmDeposit() public {
    //     testContract.farmDeposit(testUser1, testUser1, testUser1, 12);
    // }

    // function testGetReward() public {
    //     vm.prank(testUser1);
    //     testContract.getReward();
    // }

    // function testClaimReward() public {
    //     testContract.claimReward();
    // }
}
