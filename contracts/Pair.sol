// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./interfaces/IPair.sol";
import "./ERC20.sol";
import "./libraries/Math.sol";
import "./libraries/SafeTransfer.sol";
import "./libraries/UQ112x112.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IDex.sol";
import "./Errors.sol";

contract Pair is IPair, ERC20 {
    using SafeMath for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10 ** 3;

    address public factory;
    address public token0;
    address public token1;

    // Reserves and last block timestamp used for price calculation.
    // reserve0, reserve1 and blockTimestampLast stored efficiently in a single slot.
    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    constructor() {
        factory = msg.sender;
    }

    /**
     * @notice Initializes the pair with two token addresses. Can only be called once by the factory.
     * @param _token0 Address of the first token in the pair.
     * @param _token1 Address of the second token in the pair.
     */
    function initialize(address _token0, address _token1) external {
        if (msg.sender != factory) revert OnlyFactoryAllowed();

        token0 = _token0;
        token1 = _token1;
    }

    /**
     * @notice Updates the reserves and block timestamp after a liquidity change.
     * @dev Ensures reserves are within uint112 limits to prevent overflow.
     * @param balance0 New balance of token0 in the contract.
     * @param balance1 New balance of token1 in the contract.
     */
    function _update(
        uint balance0,
        uint balance1
    ) private {
        if (balance0 > type(uint112).max || balance1 > type(uint112).max)
            revert BalanceOverflow();

        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
    }

    /**
     * @notice Returns the current reserves and last block timestamp.
     * @return _reserve0 Current reserve of token0.
     * @return _reserve1 Current reserve of token1.
     * @return _blockTimestampLast Timestamp of the last reserve update.
     */
    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    /**
     * @dev Adds liquidity to the pool by transferring token amounts from sender.
     * @param amount0In Amount of token0 being added.
     * @param amount1In Amount of token1 being added.
     * @return liquidity Amount of liquidity tokens minted.
     */
    function addLiquidity(
        uint amount0In,
        uint amount1In
    ) external returns (uint liquidity) {
        if (amount0In == 0 || amount1In == 0) revert InsufficientInputAmount();

        // Transfer both tokens to liquidity pool
        SafeTransfer.safeTransferFrom(
            token0,
            msg.sender,
            address(this),
            amount0In
        );
        SafeTransfer.safeTransferFrom(
            token1,
            msg.sender,
            address(this),
            amount1In
        );

        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));

        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0In.mul(amount1In)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                amount0In.mul(_totalSupply) / _reserve0,
                amount1In.mul(_totalSupply) / _reserve1
            );
        }

        if (liquidity == 0) revert InsufficientLiquidityMinted();

        _mint(msg.sender, liquidity);
        _update(balance0, balance1);
        emit Mint(msg.sender, amount0In, amount1In, liquidity);
    }

    /**
     * @dev Removes liquidity from the pool and transfers tokens to sender.
     * @param liquidity Amount of liquidity tokens being burned.
     * @return amount0Out Amount of token0 returned.
     * @return amount1Out Amount of token1 returned.
     */
    function removeLiquidity(
        uint liquidity
    ) external returns (uint amount0Out, uint amount1Out) {
        if (balanceOf[msg.sender] < liquidity) revert InsufficientLiquidity();

        address _token0 = token0;
        address _token1 = token1;
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));

        uint _totalSupply = totalSupply;
        amount0Out = liquidity.mul(balance0) / _totalSupply;
        amount1Out = liquidity.mul(balance1) / _totalSupply;

        if (amount0Out == 0 || amount1Out == 0)
            revert InsufficientLiquidityBurned();

        _burn(msg.sender, liquidity);
        SafeTransfer.safeTransfer(_token0, msg.sender, amount0Out);
        SafeTransfer.safeTransfer(_token1, msg.sender, amount1Out);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1);
        emit Burn(msg.sender, amount0Out, amount1Out, liquidity);
    }

    /**
     * @dev Executes a token swap, ensuring pool reserves remain balanced.
     * @param _amount0In Amount of token0 being swapped (0 if swapping token1).
     * @param _amount1In Amount of token1 being swapped (0 if swapping token0).
     * @return _amountOut Amount of token received in exchange.
     */
    function swap(
        uint _amount0In,
        uint _amount1In
    ) external returns (uint _amountOut) {
        if (_amount0In == 0 && _amount1In == 0) revert InsufficientInputAmount();
        if (_amount0In != 0 && _amount1In != 0) revert InvalidInputAmount();

        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings

        (
            uint amountIn,
            uint reserveIn,
            uint reserveOut,
            address tokenIn,
            address tokenOut
        ) = _amount0In > 0
                ? (_amount0In, _reserve0, _reserve1, token0, token1)
                : (_amount1In, _reserve1, _reserve0, token1, token0);

        SafeTransfer.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            amountIn
        );

        // Apply 0.2% swap fee
        uint amountInWithFee = amountIn.mul(998).div(1000);
        // Calculate output amount
        _amountOut = reserveOut.mul(amountInWithFee).div(reserveIn.add(amountInWithFee));
        if (_amountOut > reserveOut) revert InsufficientLiquidity();

        // Withdraw output amount
        SafeTransfer.safeTransfer(tokenOut, msg.sender, _amountOut);

        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this))
        );
        emit Swap(msg.sender, _amount0In, _amount1In, _amountOut);
    }
}
