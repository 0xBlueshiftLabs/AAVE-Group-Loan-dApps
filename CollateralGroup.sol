// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./IERC20.sol";
import "./ILendingPool.sol";

contract CollateralGroup {
	ILendingPool pool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
	IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
	IERC20 aDai = IERC20(0x028171bCA77440897B824Ca71D1c56caC55b68A3); 

	uint depositAmount = 10000e18;
	address[] members;

	mapping(address => bool) isMemberMap;

	constructor(address[] memory _members) {
        members = _members;

		for (uint i = 0; i < members.length; i++) {
			dai.transferFrom(members[i], address(this), depositAmount);
			isMemberMap[members[i]] = true;
		}

		uint total = depositAmount*members.length;

		dai.approve(address(pool), total);
		pool.deposit(address(dai), total, address(this), 0);

	}

	modifier isMember() {
		require(isMemberMap[msg.sender], "Only members can access this function.");
		_;
	}

	function withdraw() external isMember {
		uint totalBalance = aDai.balanceOf(address(this));
		uint share = totalBalance/(members.length);
		aDai.approve(address(pool), totalBalance);
		for (uint i = 0; i < members.length; i++) {
			pool.withdraw(address(dai), share, members[i]);
		}
	}

	function borrow(address asset, uint amount) external isMember {
		
		pool.borrow(asset, amount, 1, 0, address(this)); // borrows from pool
		(,,,,, uint healthFactor) = pool.getUserAccountData(address(this));
		require(healthFactor > 2e18, "Collateral/borrow ratio is unhealthy. Risk of liquidation.");
		IERC20(asset).transfer(msg.sender, amount); // withdraws to borrower 
	}

	function repay(address asset, uint amount) external {
		
		IERC20(asset).transferFrom(msg.sender, address(this), amount); // transfers to this smart contract
		dai.approve(address(pool), amount);
		pool.repay(asset, amount, 1, address(this));

	}
}