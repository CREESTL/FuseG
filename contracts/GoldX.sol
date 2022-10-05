// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GOLDX is ERC20{
    constructor(
        address _teamWallet,
        address _marketing,
        address _rewardVault,
        address _multiSigVault
    )
        ERC20("GOLDX", "GOLDX")
    {
        _mint(_teamWallet, 5_000_000 * 1e18);
        _mint(_marketing, 5_000_000 * 1e18);
        _mint(_rewardVault, 101_110_100 * 1e18);
        _mint(_multiSigVault, 2_088_889_900 * 1e18);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}

