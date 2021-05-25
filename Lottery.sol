//SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./IERC20.sol";
import "./ILendingPool.sol";

contract Lottery {
	// the timestamp of the drawing event
	uint public drawing;
	// the price of the ticket in DAI (100 DAI)
	uint ticketPrice = 100e18;

	mapping(address => bool) isTicketOwner;
	mapping(uint => address) ticketNumber;
	uint numberOfTickets = 0;

	ILendingPool pool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
	IERC20 aDai = IERC20(0x028171bCA77440897B824Ca71D1c56caC55b68A3); 
	IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

	constructor() {
        drawing = block.timestamp + 1 weeks;
	}

	function purchase() external {
		require(isTicketOwner[msg.sender]==false, "You already have a ticket."); // checks if address already owns a ticket
        dai.transferFrom(msg.sender, address(this), ticketPrice);
		isTicketOwner[msg.sender] = true; // logs that address now owns a ticket
		numberOfTickets = numberOfTickets + 1; // increments number of tickets sold
		ticketNumber[(numberOfTickets)] = msg.sender; // asigns ticket number to address
		
		dai.approve(address(pool), ticketPrice);
		pool.deposit(address(dai), ticketPrice, address(this), 0);
		
	}

	event Winner(address);

	function pickWinner() external {
        require(block.timestamp >= drawing, "Attempting to draw too early.");
		uint winningTicketNumber = uint(blockhash((block.number)-40)) % numberOfTickets;
		emit Winner(ticketNumber[winningTicketNumber]);
		aDai.approve(address(pool), aDai.balanceOf(address(this)));

		for (uint i = 1; i <= numberOfTickets; i++) { // returns all funds
			if (i == winningTicketNumber) {
				continue;
			}
			else {
				pool.withdraw(address(dai), ticketPrice, ticketNumber[i]); // refunds losers
		    }
		}

		pool.withdraw(address(dai), aDai.balanceOf(address(this)), ticketNumber[winningTicketNumber]); // transfers to winner
		
	}
}