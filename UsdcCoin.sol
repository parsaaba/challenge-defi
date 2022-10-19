// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract devUSDC is ERC20, Ownable {
    mapping(address => bool) private minters;

    constructor() ERC20("devUSDC", "devUSDC") {}

    modifier onlyMinter() {
        require(minters[msg.sender], "caller is not the minter");
        _;
    }

    function addMinter(address minter) external onlyOwner {
        minters[minter] = true;
    }

    function mint(uint256 amount, address receiver) external onlyMinter {
        _mint(receiver, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 26;
    }
}
