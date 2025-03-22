// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TrifectaNFT.sol";

contract TrifectaNFTTest is Test {
    TrifectaNFT public nft;
    address public owner;
    address public user;
    address public minter;
    string constant TEST_URI = "ipfs://QmTest";

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        minter = address(0x2);
        
        vm.startPrank(owner);
        nft = new TrifectaNFT();
        vm.stopPrank();
    }

    function testInitialSetup() public {
        assertEq(nft.name(), "TrifectaNFT");
        assertEq(nft.symbol(), "TNFT");
        assertTrue(nft.hasRole(nft.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(nft.hasRole(nft.MINTER_ROLE(), owner));
    }

    function testMintingWithMinterRole() public {
        vm.startPrank(owner);
        nft.grantRole(nft.MINTER_ROLE(), minter);
        vm.stopPrank();

        vm.startPrank(minter);
        nft.safeMint(user, TEST_URI);
        vm.stopPrank();

        assertEq(nft.ownerOf(0), user);
        assertEq(nft.tokenURI(0), TEST_URI);
    }

    function testMintingWithoutMinterRole() public {
        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControl.AccessControlUnauthorizedAccount.selector,
                user,
                nft.MINTER_ROLE()
            )
        );
        nft.safeMint(user, TEST_URI);
        vm.stopPrank();
    }

    function testTransferNFT() public {
        // Mint NFT
        vm.startPrank(owner);
        nft.safeMint(owner, TEST_URI);
        
        // Transfer NFT
        nft.transferFrom(owner, user, 0);
        vm.stopPrank();

        assertEq(nft.ownerOf(0), user);
    }

    function testApproveAndTransfer() public {
        // Mint NFT
        vm.startPrank(owner);
        nft.safeMint(owner, TEST_URI);
        nft.approve(user, 0);
        vm.stopPrank();

        // Transfer using approval
        vm.startPrank(user);
        nft.transferFrom(owner, user, 0);
        vm.stopPrank();

        assertEq(nft.ownerOf(0), user);
    }

    function testBurnNFT() public {
        // Mint NFT
        vm.startPrank(owner);
        nft.safeMint(owner, TEST_URI);
        
        // Burn NFT
        vm.expectRevert("ERC721: invalid token ID");
        nft.tokenURI(1);
        
        nft.burn(0);
        
        vm.expectRevert("ERC721: invalid token ID");
        nft.ownerOf(0);
        vm.stopPrank();
    }
} 