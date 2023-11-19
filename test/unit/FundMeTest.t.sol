//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

//import {Test, console} from "forge-std/Test.sol";
import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user"); // makeAddrs creates a fake address
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // deal gives USER a fake balance
    }

    function testDemo() public {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        console.log(address(fundMe));
        assertEq(fundMe.MIN_USD(), 5e18);
    }

    function testGetversion() public {
        uint256 version = fundMe.getversion();
        assertEq(version, 3);
    }

    function testIsTheFundEnough() public {
        vm.prank(USER);
        fundMe.fundMe{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAmountFundedByAddress(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testCheckingTheEthPrice() public {
        uint256 ethPrice = fundMe.getEthPrice();
        assertEq(ethPrice, 2000e8);
    }

    //using cheatcoodes
    modifier funded() {
        vm.prank(USER);
        fundMe.fundMe{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        console.log(fundMe.getOwner()); //who's the deployer?
        console.log(address(fundMe));
        console.log(address(this));
        console.log(msg.sender);

        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testwhoCanWithdrawMoney() public {
        fundMe.fundMe{value: SEND_VALUE};
        vm.expectRevert();
        vm.prank(fundMe.getOwner());
        fundMe.withdraw(); // adress(this) can't call withdraw
    }

    //Arrange
    //Act
    //Assert
    function testCheckingWithdrawWithMultipleFunders() public funded {
        uint160 numberofIndexes = 10;
        uint160 startingIndex = 1;
        for (uint160 i = startingIndex; i < numberofIndexes; i++) {
            hoax(address(i), SEND_VALUE); // address(i) only works with uint160
            fundMe.fundMe{value: SEND_VALUE}();
        }

        uint256 ownerBalanceBefore = fundMe.getOwner().balance;
        uint256 contractBalanceBefore = address(fundMe).balance;

        uint256 gasBefore = gasleft();
        vm.txGasPrice(GAS_PRICE); //this line changes gas price from 0 to the argument given
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 gasAfter = gasleft();
        uint256 gasUsed = (gasBefore - gasAfter) * GAS_PRICE;
        console.log(gasUsed);

        assert(address(fundMe).balance == 0);
        assert(
            fundMe.getOwner().balance ==
                ownerBalanceBefore + contractBalanceBefore
        );
    }
}
