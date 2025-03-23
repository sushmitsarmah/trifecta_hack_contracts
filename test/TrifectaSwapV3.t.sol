// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import "forge-std/Test.sol";
import "../src/TrifectaSwapV3.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }
}

contract MockSwapRouter {
    function exactInputSingle(ISwapRouter.ExactInputSingleParams calldata params)
        external
        returns (uint256 amountOut)
    {
        // Calculate amount out
        amountOut = params.amountIn * 90 / 100; // Simulating 1% fee
        
        // Transfer input token from sender to this contract
        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
        
        // Transfer output token to recipient
        IERC20(params.tokenOut).transfer(params.recipient, amountOut);
        
        return amountOut;
    }
    
    function exactOutputSingle(ISwapRouter.ExactOutputSingleParams calldata params)
        external
        returns (uint256 amountIn)
    {
        // Calculate amount in needed
        amountIn = params.amountOut * 120 / 100; // Simulating 1% slippage
        
        // Transfer input token from sender to this contract
        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), amountIn);
        
        // Transfer output token to recipient
        IERC20(params.tokenOut).transfer(params.recipient, params.amountOut);
        
        return amountIn;
    }
}

contract TrifectaSwapV3Test is Test {
    TrifectaSwapV3 public trifectaSwapV3;
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    MockSwapRouter public mockRouter;
    address public user;

    function setUp() public {
        tokenA = new MockERC20("TokenA", "TKA");
        tokenB = new MockERC20("TokenB", "TKB");
        mockRouter = new MockSwapRouter();
        trifectaSwapV3 = new TrifectaSwapV3(address(mockRouter));

        uint256 privateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        user = vm.rememberKey(privateKey); // Generates the correct public address
        vm.deal(user, 100 ether); // Fund user with ETH for gas
        
        tokenA.transfer(user, 1000 * 10 ** tokenA.decimals());
        tokenB.transfer(user, 1000 * 10 ** tokenB.decimals());

        // Transfer some tokens to the mock router to enable it to return tokens
        tokenA.transfer(address(mockRouter), 10000 * 10 ** tokenA.decimals());
        tokenB.transfer(address(mockRouter), 10000 * 10 ** tokenB.decimals());
    }

    function testSwapExactInputSingle() public {
        vm.startPrank(user);
        tokenA.approve(address(trifectaSwapV3), 1000);
        
        int256 initialProfit = trifectaSwapV3.userProfits(user);
        uint256 initialBuySwaps = trifectaSwapV3.buySwaps(user);

        uint256 amountOut = trifectaSwapV3.swapExactInputSingle(
            address(tokenA),
            address(tokenB),
            3000,
            100,
            90
        );

        int256 finalProfit = trifectaSwapV3.userProfits(user);
        uint256 finalBuySwaps = trifectaSwapV3.buySwaps(user);

        // Log final values
        console.log("Amount out:", amountOut);
        console.log("Final profit:", finalProfit);
        console.log("Final buy swaps:", finalBuySwaps);

        assertTrue(amountOut >= 90);
        assertTrue(finalProfit > initialProfit);
        // assertEq(finalBuySwaps, initialBuySwaps + 1);
        vm.stopPrank();
    }

    function testSwapExactOutputSingle() public {
        vm.startPrank(user);
        tokenA.approve(address(trifectaSwapV3), 200);
        
        int256 initialProfit = trifectaSwapV3.userProfits(user);
        uint256 initialSellSwaps = trifectaSwapV3.sellSwaps(user);

        uint256 amountIn = trifectaSwapV3.swapExactOutputSingle(
            address(tokenA),
            address(tokenB),
            3000,
            100,
            120
        );

        int256 finalProfit = trifectaSwapV3.userProfits(user);
        uint256 finalSellSwaps = trifectaSwapV3.sellSwaps(user);

        // Log final values
        console.log("Amount in:", amountIn);
        console.log("Final profit:", finalProfit);
        console.log("Final sell swaps:", finalSellSwaps);

        assertTrue(amountIn <= 120);
        assertTrue(finalProfit > initialProfit);
        // assertEq(finalSellSwaps, initialSellSwaps + 1);
        vm.stopPrank();
    }
}
