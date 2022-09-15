pragma solidity ^0.8.10;

import "./interfaces/IMiniswapV2Pair.sol";
import "./interfaces/IMiniswapV2Factory.sol";
import "./MiniswapV2Library.sol";

contract MiniswapV2Router {
    error InsufficientAAmount();
    error InsufficientBAmount();
    error SafeTransferFailed();    
    error TransferFailed();
    IMiniswapV2Factory factory;

    constructor(address factoryAddress) {
        factory = IMiniswapV2Factory(factoryAddress);
    }

    function addLiquidity(address tokenA, address tokenB, 
    uint256 amountADesired, uint256 amountBDesired, 
    uint256 amountAMin, uint256 amountBMin, address to)
    public returns(uint256 amountA, uint256 amountB, uint256 liquidity) {
        if (factory.pairs(tokenA, tokenB) == address(0)) {
            factory.createPair(tokenA, tokenB);
        }

        (amountA, amountB) = _calculateLiquidity(
            tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin
        );

        address pairAddress = MiniswapV2Library.pairFor(address(factory), tokenA, tokenB);

        _safeTransferFrom(tokenA, msg.sender, pairAddress, amountA);
        _safeTransferFrom(tokenB, msg.sender, pairAddress, amountB);
        liquidity = IMiniswapV2Pair(pairAddress).mint(to);
    }

    function _calculateLiquidity(address tokenA, address tokenB, 
    uint256 amountADesired, uint256 amountBDesired, 
    uint256 amountAMin, uint256 amountBMin) internal returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB) = MiniswapV2Library.getReserves(
            address(factory),
            tokenA,
            tokenB
        );

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = MiniswapV2Library.quote(
                amountADesired, reserveA, reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal <= amountBMin) revert InsufficientBAmount();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
            uint256 amountAOptimal = MiniswapV2Library.quote(
                amountBDesired, reserveB, reserveA
            );                
            assert(amountAOptimal <= amountADesired);

            if (amountAOptimal <= amountAMin) revert InsufficientAAmount();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,address,uint256)", from, to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert TransferFailed();
        }
    }    
}