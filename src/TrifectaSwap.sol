// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import "v4-core/contracts/interfaces/IHookFeeManager.sol";
import "v4-periphery/contracts/libraries/TransferHelper.sol";
import "v4-periphery/contracts/interfaces/ISwapRouter.sol";

contract TrifectaSwap is Ownable {
    IPoolManager public immutable poolManager;
    ISwapRouter public immutable swapRouter;
    
    // v4 fee tiers - similar to v3 but actual implementation depends on the pool manager configuration
    uint24[] public feeTiers = [100, 500, 3000, 10000]; // 0.01%, 0.05%, 0.3%, 1%
    
    struct PoolKey {
        address currency0;
        address currency1;
        uint24 fee;
    }
    
    struct PoolInfo {
        bytes32 poolId;
        uint24 fee;
        uint256 liquidity;
    }
    
    constructor(address _poolManager, address _swapRouter) Ownable(msg.sender) {
        poolManager = IPoolManager(_poolManager);
        swapRouter = ISwapRouter(_swapRouter);
    }
    
    function findBestPool(address tokenA, address tokenB) public view returns (PoolInfo memory) {
        PoolInfo memory bestPool;
        uint256 maxLiquidity = 0;
        
        // Sort tokens for consistent pool key creation
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        
        for (uint256 i = 0; i < feeTiers.length; i++) {
            PoolKey memory poolKey = PoolKey({
                currency0: token0,
                currency1: token1,
                fee: feeTiers[i]
            });
            
            // In v4, we get poolId by hashing the PoolKey
            bytes32 poolId = keccak256(abi.encode(poolKey));
            
            // Check if pool exists by fetching liquidity
            try poolManager.getLiquidity(poolId) returns (uint256 liquidity) {
                if (liquidity > maxLiquidity) {
                    maxLiquidity = liquidity;
                    bestPool = PoolInfo({
                        poolId: poolId,
                        fee: feeTiers[i],
                        liquidity: liquidity
                    });
                }
            } catch {
                // Pool doesn't exist or other error, continue to next fee tier
                continue;
            }
        }
        
        require(bestPool.liquidity > 0, "No pool found with liquidity");
        return bestPool;
    }
    
    function swapExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) external returns (uint256 amountOut) {
        // Find the best pool for the swap
        PoolInfo memory bestPool = findBestPool(tokenIn, tokenOut);
        
        // Transfer tokens from sender to this contract
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);
        
        // In v4, we use the swap router with the pool ID
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            poolId: bestPool.poolId,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            recipient: msg.sender,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0,
            hookData: "" // New in v4 - optional data for hooks
        });
        
        amountOut = swapRouter.exactInputSingle(params);
    }
    
    function swapExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 amountInMaximum
    ) external returns (uint256 amountIn) {
        // Find the best pool for the swap
        PoolInfo memory bestPool = findBestPool(tokenIn, tokenOut);
        
        // Transfer tokens from sender to this contract
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountInMaximum);
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountInMaximum);
        
        // In v4, we use the swap router with the pool ID
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            poolId: bestPool.poolId,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            recipient: msg.sender,
            amountOut: amountOut,
            amountInMaximum: amountInMaximum,
            sqrtPriceLimitX96: 0,
            hookData: "" // New in v4 - optional data for hooks
        });
        
        amountIn = swapRouter.exactOutputSingle(params);
        
        // Refund unused tokens
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(tokenIn, address(swapRouter), 0);
            TransferHelper.safeTransfer(tokenIn, msg.sender, amountInMaximum - amountIn);
        }
    }
}
