pragma solidity ^0.8.10;

interface IMiniswapV2Factory {
    function pairs(address, address) external pure returns (address);

    function createPair(address, address) external returns (address);
}