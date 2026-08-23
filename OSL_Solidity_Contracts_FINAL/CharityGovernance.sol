// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CharityGovernance is Ownable {
    IERC20 public immutable oslToken;
    struct Cause { string name; uint256 voteCount; bool active; }
    Cause[] public causes;
    uint256 public votingRound;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    constructor(address _oslToken) Ownable(msg.sender) {
        require(_oslToken != address(0), "Invalid token address");
        oslToken = IERC20(_oslToken);
        causes.push(Cause("Health", 0, true));
        causes.push(Cause("Animals", 0, true));
        causes.push(Cause("Food and Famine", 0, true));
    }

    function vote(uint256 causeId) external {
        require(causeId < causes.length, "Invalid cause");
        require(causes[causeId].active, "Cause inactive");
        require(!hasVoted[votingRound][msg.sender], "Already voted");
        uint256 power = oslToken.balanceOf(msg.sender);
        require(power > 0, "Need OSL to vote");
        causes[causeId].voteCount += power;
        hasVoted[votingRound][msg.sender] = true;
    }

    function startNewVotingRound() external onlyOwner {
        votingRound++;
        for (uint256 i = 0; i < causes.length; i++) causes[i].voteCount = 0;
    }

    function addCause(string calldata name) external onlyOwner {
        require(bytes(name).length > 0, "Empty cause name");
        causes.push(Cause(name, 0, true));
    }

    function deactivateCause(uint256 causeId) external onlyOwner {
        require(causeId < causes.length, "Invalid cause");
        causes[causeId].active = false;
    }

    function getCause(uint256 causeId) external view returns (string memory, uint256, bool) {
        require(causeId < causes.length, "Invalid cause");
        Cause memory c = causes[causeId];
        return (c.name, c.voteCount, c.active);
    }

    function getNumberOfCauses() external view returns (uint256) { return causes.length; }
}
