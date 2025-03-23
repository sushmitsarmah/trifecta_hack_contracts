// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TrifectaSwapV3 {
    address public immutable swapRouter;
    mapping(address => int256) public userProfits;
    mapping(address => uint256) public buySwaps;
    mapping(address => uint256) public sellSwaps;

    constructor(address _swapRouter) {
        swapRouter = _swapRouter;
    }

    function swapExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (uint256 amountOut) {
        require(amountIn > 0, "Amount must be greater than 0");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(swapRouter, amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp + 15 minutes,
            amountIn: amountIn,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0
        });

        amountOut = ISwapRouter(swapRouter).exactInputSingle(params);
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        userProfits[msg.sender] += int256(amountOut) - int256(amountIn);
        buySwaps[msg.sender] += 1;
    }

    function swapExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint256 amountOut,
        uint256 amountInMax
    ) external returns (uint256 amountIn) {
        require(amountOut > 0, "Amount must be greater than 0");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountInMax);
        IERC20(tokenIn).approve(swapRouter, amountInMax);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp + 15 minutes,
            amountOut: amountOut,
            amountInMaximum: amountInMax,
            sqrtPriceLimitX96: 0
        });

        amountIn = ISwapRouter(swapRouter).exactOutputSingle(params);
        IERC20(tokenOut).transfer(msg.sender, amountOut);
        IERC20(tokenIn).transfer(msg.sender, amountInMax - amountIn);

        userProfits[msg.sender] += int256(amountOut) - int256(amountIn);
        sellSwaps[msg.sender] += 1;
    }
}
