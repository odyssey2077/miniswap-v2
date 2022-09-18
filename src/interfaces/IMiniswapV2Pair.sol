pragma solidity ^0.8.10;

interface IMiniswapV2Pair {
    function mint(address) external returns (uint256);
    function initialize(address, address) external;

    function getReserves()
        external
        returns (
            uint112,
            uint112,
            uint32
        );    

    function transferFrom(address from, address to, uint256 amount) external;

    function burn(address) external returns (uint256, uint256);
}