// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { UniversalRouter } from "universal-router/contracts/UniversalRouter.sol";
import { Commands } from "universal-router/contracts/libraries/Commands.sol";
import { IPoolManager } from "v4-core/src/interfaces/IPoolManager.sol";
import { IV4Router } from "v4-periphery/src/interfaces/IV4Router.sol";
import { Actions } from "v4-periphery/src/libraries/Actions.sol";
import { IPermit2 } from "permit2/src/interfaces/IPermit2.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";

contract TrifectaSwap is Ownable {
    using StateLibrary for IPoolManager;

    UniversalRouter public immutable router;
    IPoolManager public immutable poolManager;
    IPermit2 public immutable permit2;

    struct PoolKey {
        Currency currency0;
        Currency currency1;
        uint24 fee;
        int24 tickSpacing;
        IHooks hooks;
    }
    
    constructor(address _router, address _poolManager, address _permit2) {
        router = UniversalRouter(_router);
        poolManager = IPoolManager(_poolManager);
        permit2 = IPermit2(_permit2);
    }

    function approveTokenWithPermit2(
        address token,
        uint160 amount,
        uint48 expiration
    ) external {
        IERC20(token).approve(address(permit2), type(uint256).max);
        permit2.approve(token, address(router), amount, expiration);
    }

    function swapExactInputSingle(
        PoolKey calldata key, // PoolKey struct that identifies the v4 pool
        uint128 amountIn, // Exact amount of tokens to swap
        uint128 minAmountOut, // Minimum amount of output tokens expected
        uint256 deadline // Timestamp after which the transaction will revert
    ) external returns (uint256 amountOut) {
        // Encode the Universal Router command
        bytes memory command = abi.encodePacked(uint8(Commands.V4_SWAP));
        bytes[] memory inputs = new bytes[](1);

        // Encode V4Router actions
        bytes memory actions = abi.encodePacked(
            uint8(Actions.SWAP_EXACT_IN_SINGLE),
            uint8(Actions.SETTLE_ALL),
            uint8(Actions.TAKE_ALL)
        );

        // Prepare parameters for each action
        bytes[] memory params = new bytes[](3);
        params[0] = abi.encode(
            IV4Router.ExactInputSingleParams({
                poolKey: key,
                zeroForOne: true,
                amountIn: amountIn,
                amountOutMinimum: minAmountOut,
                hookData: bytes("")
            })
        );
        params[1] = abi.encode(key.currency0, amountIn);
        params[2] = abi.encode(key.currency1, minAmountOut);

        // Combine actions and params into inputs
        inputs[0] = abi.encode(actions, params);

        // Execute the swap
        router.execute(commands, inputs, deadline);

        // Verify and return the output amount
        amountOut = IERC20(key.currency1).balanceOf(address(this));
        require(amountOut >= minAmountOut, "Insufficient output amount");
        return amountOut;

    }
}
        
    
    // function findBestPool(address tokenA, address tokenB) public view returns (PoolInfo memory) {
    //     PoolInfo memory bestPool;
    //     uint256 maxLiquidity = 0;
        
    //     // Sort tokens for consistent pool key creation
    //     (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        
    //     for (uint256 i = 0; i < feeTiers.length; i++) {
    //         PoolKey memory poolKey = PoolKey({
    //             currency0: token0,
    //             currency1: token1,
    //             fee: feeTiers[i]
    //         });
            
    //         // In v4, we get poolId by hashing the PoolKey
    //         bytes32 poolId = keccak256(abi.encode(poolKey));
            
    //         // Check if pool exists by fetching liquidity
    //         try poolManager.getLiquidity(poolId) returns (uint256 liquidity) {
    //             if (liquidity > maxLiquidity) {
    //                 maxLiquidity = liquidity;
    //                 bestPool = PoolInfo({
    //                     poolId: poolId,
    //                     fee: feeTiers[i],
    //                     liquidity: liquidity
    //                 });
    //             }
    //         } catch {
    //             // Pool doesn't exist or other error, continue to next fee tier
    //             continue;
    //         }
    //     }
        
    //     require(bestPool.liquidity > 0, "No pool found with liquidity");
    //     return bestPool;
    // }
    
    // function swapExactInputSingle(
    //     address tokenIn,
    //     address tokenOut,
    //     uint256 amountIn,
    //     uint256 amountOutMinimum
    // ) external returns (uint256 amountOut) {
    //     // Find the best pool for the swap
    //     PoolInfo memory bestPool = findBestPool(tokenIn, tokenOut);
        
    //     // Transfer tokens from sender to this contract
    //     TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
    //     TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);
        
    //     // In v4, we use the swap router with the pool ID
    //     ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
    //         poolId: bestPool.poolId,
    //         tokenIn: tokenIn,
    //         tokenOut: tokenOut,
    //         recipient: msg.sender,
    //         amountIn: amountIn,
    //         amountOutMinimum: amountOutMinimum,
    //         sqrtPriceLimitX96: 0,
    //         hookData: "" // New in v4 - optional data for hooks
    //     });
        
    //     amountOut = swapRouter.exactInputSingle(params);
    // }
    
    // function swapExactOutputSingle(
    //     address tokenIn,
    //     address tokenOut,
    //     uint256 amountOut,
    //     uint256 amountInMaximum
    // ) external returns (uint256 amountIn) {
    //     // Find the best pool for the swap
    //     PoolInfo memory bestPool = findBestPool(tokenIn, tokenOut);
        
    //     // Transfer tokens from sender to this contract
    //     TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountInMaximum);
    //     TransferHelper.safeApprove(tokenIn, address(swapRouter), amountInMaximum);
        
    //     // In v4, we use the swap router with the pool ID
    //     ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
    //         poolId: bestPool.poolId,
    //         tokenIn: tokenIn,
    //         tokenOut: tokenOut,
    //         recipient: msg.sender,
    //         amountOut: amountOut,
    //         amountInMaximum: amountInMaximum,
    //         sqrtPriceLimitX96: 0,
    //         hookData: "" // New in v4 - optional data for hooks
    //     });
        
    //     amountIn = swapRouter.exactOutputSingle(params);
        
    //     // Refund unused tokens
    //     if (amountIn < amountInMaximum) {
    //         TransferHelper.safeApprove(tokenIn, address(swapRouter), 0);
    //         TransferHelper.safeTransfer(tokenIn, msg.sender, amountInMaximum - amountIn);
    //     }
    // }
// }
