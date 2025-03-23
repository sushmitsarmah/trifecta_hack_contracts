// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TrifectaToken.sol";

contract TrifectaTokenTest is Test {
    TrifectaToken public token;
    address public owner;
    address public user;
    address public minter;

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        minter = address(0x2);
        
        vm.startPrank(owner);
        token = new TrifectaToken();
        vm.stopPrank();
    }

    function testInitialSetup() public {
        assertEq(token.name(), "Trifecta");
        assertEq(token.symbol(), "TRI");
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(token.hasRole(token.MINTER_ROLE(), owner));
    }

    function testMintingWithMinterRole() public {
        vm.startPrank(owner);
        token.grantRole(token.MINTER_ROLE(), minter);
        vm.stopPrank();

        vm.startPrank(minter);
        token.mint(user, 1000);
        vm.stopPrank();

        assertEq(token.balanceOf(user), 1000);
    }

    function testMintingWithoutMinterRole() public {
        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControl.AccessControlUnauthorizedAccount.selector,
                user,
                token.MINTER_ROLE()
            )
        );
        token.mint(user, 1000);
        vm.stopPrank();
    }

    function testTransfer() public {
        vm.startPrank(owner);
        token.mint(owner, 1000);
        token.transfer(user, 500);
        vm.stopPrank();

        assertEq(token.balanceOf(owner), 500);
        assertEq(token.balanceOf(user), 500);
    }

    function testPermit() public {
        uint256 privateKey = 0xA11CE;
        address owner = vm.addr(privateKey);
        address spender = address(0xB0B);
        uint256 value = 1000;
        uint256 deadline = block.timestamp + 1 hours;
        
        // Get the current nonce
        uint256 nonce = token.nonces(owner);
        
        // Calculate permit digest
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                        owner,
                        spender,
                        value,
                        nonce,
                        deadline
                    )
                )
            )
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        
        token.permit(owner, spender, value, deadline, v, r, s);
        assertEq(token.allowance(owner, spender), value);
    }
} 