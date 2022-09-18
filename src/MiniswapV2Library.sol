pragma solidity ^0.8.10;
import "./interfaces/IMiniswapV2Factory.sol";
import "./interfaces/IMiniswapV2Pair.sol";
import {MiniswapV2Pair} from "./MiniswapV2Pair.sol";


library MiniswapV2Library {
    error InsufficientAmount();
    error InsufficientLiquidity();

    function getReserves(address factoryAddress,
     address tokenA, address tokenB) public returns (uint256 reserveA, uint256 reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IMiniswapV2Pair(pairFor(factoryAddress, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function quote(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256 amountOut) {
        if (amountIn == 0) revert InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();
        amountOut = (amountIn * reserveOut) / reserveIn;
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        if (amountIn == 0) revert InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        return numerator / denominator;
    }

    function sortTokens(address tokenA, address tokenB) public pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function pairFor(address factoryAddress, address tokenA, address tokenB) internal pure returns (address pairAddress) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pairAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factoryAddress,
                            keccak256(abi.encodePacked(token0, token1)),
                            keccak256(type(MiniswapV2Pair).creationCode)
                        )
                    )
                )
            )
        );        
    }
}
