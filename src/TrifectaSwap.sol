// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract TrifectaSwap is Ownable {
    IUniswapV3Factory public immutable factory;
    ISwapRouter public immutable swapRouter;
    uint24[] public feeTiers = [100, 500, 3000, 10000]; // 0.01%, 0.05%, 0.3%, 1%

    constructor(address _factory, address _swapRouter) Ownable(msg.sender) {
        factory = IUniswapV3Factory(_factory);
        swapRouter = ISwapRouter(_swapRouter);
    }

    struct PoolInfo {
        address pool;
        uint24 fee;
        uint128 liquidity;
    }

    function findBestPool(address tokenA, address tokenB) public view returns (PoolInfo memory) {
        PoolInfo memory bestPool;
        uint128 maxLiquidity = 0;

        for (uint256 i = 0; i < feeTiers.length; i++) {
            address pool = factory.getPool(tokenA, tokenB, feeTiers[i]);
            if (pool == address(0)) continue;

            uint128 liquidity = IUniswapV3Pool(pool).liquidity();
            if (liquidity > maxLiquidity) {
                maxLiquidity = liquidity;
                bestPool = PoolInfo({
                    pool: pool,
                    fee: feeTiers[i],
                    liquidity: liquidity
                });
            }
        }

        require(bestPool.pool != address(0), "No pool found");
        return bestPool;
    }

    function swapExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) external returns (uint256 amountOut) {
        PoolInfo memory bestPool = findBestPool(tokenIn, tokenOut);

        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: bestPool.fee,
                recipient: msg.sender,
                deadline: block.timestamp + 15 minutes,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }

    function swapExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 amountInMaximum
    ) external returns (uint256 amountIn) {
        PoolInfo memory bestPool = findBestPool(tokenIn, tokenOut);

        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountInMaximum);
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: bestPool.fee,
                recipient: msg.sender,
                deadline: block.timestamp + 15 minutes,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        amountIn = swapRouter.exactOutputSingle(params);

        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(tokenIn, address(swapRouter), 0);
            TransferHelper.safeTransfer(tokenIn, msg.sender, amountInMaximum - amountIn);
        }
    }
} 