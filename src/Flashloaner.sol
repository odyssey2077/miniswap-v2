pragma solidity ^0.8.10;
pragma solidity ^0.8.10;
import {MiniswapV2Pair} from "./MiniswapV2Pair.sol";

interface IERC20 {
    function balanceOf(address) external returns (uint256);

    function transfer(address to, uint256 amount) external;
}

contract Flashloaner {
    error InsufficientFlashLoanAmount();

    uint256 expectedLoanAmount;

    function flashloan(address pairAddress, uint256 amount0Out, uint256 amount1Out, address tokenAddress) public {
        if (amount0Out > 0) {
            expectedLoanAmount = amount0Out;
        }
        if (amount1Out > 0) {
            expectedLoanAmount = amount1Out;
        }

        MiniswapV2Pair(pairAddress).swap(amount0Out, amount1Out, address(this), abi.encode(tokenAddress));
    }

    function miniswapV2Call(address sender, uint256 amount0Out, uint256 amount1Out, bytes calldata data) public {
        address tokenAddress = abi.decode(data, (address));
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));

        if (balance < expectedLoanAmount) revert InsufficientFlashLoanAmount();

        IERC20(tokenAddress).transfer(msg.sender, balance);        
    }
}