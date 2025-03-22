// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TrifectaSwap.sol";
import "../src/TrifectaToken.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract TrifectaSwapTest is Test {
    TrifectaSwap public swapper;
    TrifectaToken public tokenA;
    TrifectaToken public tokenB;
    
    address public owner;
    address public user;
    
    // Mainnet addresses
    address constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    
    function setUp() public {
        owner = address(this);
        user = address(0x1);
        
        // Deploy tokens
        tokenA = new TrifectaToken();
        tokenB = new TrifectaToken();
        
        // Deploy swapper
        swapper = new TrifectaSwap(UNISWAP_V3_FACTORY, UNISWAP_V3_ROUTER);
        
        // Mint initial tokens
        tokenA.mint(owner, 1000000e18);
        tokenB.mint(owner, 1000000e18);
        tokenA.mint(user, 1000e18);
        tokenB.mint(user, 1000e18);
    }

    function testConstructor() public {
        assertEq(address(swapper.factory()), UNISWAP_V3_FACTORY);
        assertEq(address(swapper.swapRouter()), UNISWAP_V3_ROUTER);
    }

    function testFindBestPool() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"));
        
        // Use mainnet USDC and WETH addresses for testing
        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        
        TrifectaSwap.PoolInfo memory bestPool = swapper.findBestPool(USDC, WETH);
        assertTrue(bestPool.pool != address(0));
        assertTrue(bestPool.liquidity > 0);
    }

    function testSwapExactInputSingle() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"));
        
        // Use mainnet USDC and WETH addresses
        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        
        // Setup test amounts
        uint256 amountIn = 1000e6; // 1000 USDC
        uint256 amountOutMinimum = 0.1e18; // 0.1 WETH
        
        vm.startPrank(user);
        
        // Approve spending
        IERC20(USDC).approve(address(swapper), amountIn);
        
        // Perform swap
        uint256 amountOut = swapper.swapExactInputSingle(
            USDC,
            WETH,
            amountIn,
            amountOutMinimum
        );
        
        assertTrue(amountOut >= amountOutMinimum);
        vm.stopPrank();
    }

    function testSwapExactOutputSingle() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"));
        
        // Use mainnet USDC and WETH addresses
        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        
        // Setup test amounts
        uint256 amountOut = 0.1e18; // Want 0.1 WETH
        uint256 amountInMaximum = 1000e6; // Max 1000 USDC
        
        vm.startPrank(user);
        
        // Approve spending
        IERC20(USDC).approve(address(swapper), amountInMaximum);
        
        // Perform swap
        uint256 amountIn = swapper.swapExactOutputSingle(
            USDC,
            WETH,
            amountOut,
            amountInMaximum
        );
        
        assertTrue(amountIn <= amountInMaximum);
        vm.stopPrank();
    }
} 