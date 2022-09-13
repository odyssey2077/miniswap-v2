pragma solidity ^0.8.10;

import "solmate/tokens/ERC20.sol";
import "./libraries/Math.sol";

interface IERC20 {
    function balanceOf(address) external returns (uint256);

    function trasnfer(address to, uint256 amount) external;
}

error InsufficientLiquidityMinted();
error InsufficientLiquidityBurned();
error TransferFailed();
error InsufficientOutputAmount();
error InsufficientLiquidity();
error InvalidK();
error BalanceOverflow();

contract MiniswapV2Pair is ERC20, Math {
    uint256 constant MINIMUM_LIQUIDITY = 1000;
    address public token0;
    address public token1;
    
    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    uint private unlocked = 1;

    event Burn(address indexed sender, uint256 amount0, uint256 amount1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Sync(uint256 reserve0, uint256 reserve1);
    event Swap(address indexed sender, uint256 amount0, uint256 amount1, address to);

    modifier lock() {
        require(unlocked == 1);
        unlocked = 0;
        _;
        unlocked = 1;
    }
    constructor(address _token0, address _token1) ERC20("MiniswapV2 LP", "MINIV2", 18) {
        token0 = _token0;
        token1 = _token1;
    }

    function mint() public {
        (uint112 reserve0_, uint112 reserve1_,) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - reserve0_;
        uint256 amount1 = balance1 - reserve1_;

        uint256 liquidity;

        if (totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply) / reserve0,
                (amount1 * totalSupply) / reserve1
            );
        }

        if (liquidity <= 0) revert InsufficientLiquidityMinted();
        _mint(msg.sender, liquidity);
        _update(balance0, balance1, reserve0_, reserve1_);
        emit Mint(msg.sender, amount0, amount1);
    }

    function burn() public {
        (uint112 reserve0_, uint112 reserve1_,) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[msg.sender];

        uint256 amount0 = (liquidity * balance0) / totalSupply;
        uint256 amount1 = (liquidity * balance1) / totalSupply;

        if (amount0 <= 0 || amount1 <= 0) revert InsufficientLiquidityBurned();
        _burn(msg.sender, liquidity);
        _safeTransfer(token0, msg.sender, amount0);
        _safeTransfer(token1, msg.sender, amount1);        

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        _update(balance0, balance1, reserve0_, reserve1_);

        emit Burn(msg.sender, amount0, amount1);
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to) public {
        if (amount0Out == 0 && amount1Out == 0) {
            revert InsufficientOutputAmount();
        }
        (uint112 reserve0_, uint112 reserve1_,) = getReserves();

        if (amount0Out > reserve0_ || amount1Out > reserve1_) {
            revert InsufficientLiquidity();
        }

        uint256 balance0 = IERC20(token0).balanceOf(address(this)) - amount0Out;
        uint256 balance1 = IERC20(token1).balanceOf(address(this)) - amount1Out;

        if (balance0 * balance1 < reserve0_ * reserve1_) 
            revert InvalidK();
        
        if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
        if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);

        _update(balance0, balance1, reserve0_, reserve1_);

        emit Swap(msg.sender, amount0Out, amount1Out, to);
    }

    function _update(uint256 balance0, uint256 balance1, uint112 reserve0_, uint112 reserve1_) private {
        if (balance0 > type(uint112).max || balance1 > type(uint112).max)
            revert BalanceOverflow();

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = uint32(block.timestamp);

        emit Sync(reserve0, reserve1);
    }

    function getReserves() public view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, 0);
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert TransferFailed();
        }
    }
}