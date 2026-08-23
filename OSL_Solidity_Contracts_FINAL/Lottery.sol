// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Lottery is Ownable, ReentrancyGuard {
    IERC20 public immutable oslToken;
    address payable public charityAddress;
    address payable public projectAddress;

    uint256 public constant ENTRY_FEE = 1 ether;
    uint256 public constant MAX_PLAYERS = 3;
    uint256 public constant PLAYER_REWARD = 1 ether;
    uint256 public constant WINNER_BONUS = 5 ether;
    uint256 public constant EXCLUSIVE_ENTRY_FEE = 100 ether;

    uint256 public oslPriceUSD = 1 ether;

    address[] public participants;
    mapping(address => bool) public isRegistered;
    address public lastWinner;
    uint256 public drawingCount;

    address[] public exclusiveParticipants;
    mapping(address => bool) public isExclusiveRegistered;
    address public lastExclusiveWinner;
    uint256 public exclusiveDrawingCount;
    uint256 public exclusivePool;

    constructor(address _oslToken, address payable _charityAddress, address payable _projectAddress)
        Ownable(msg.sender)
    {
        require(_oslToken != address(0), "Invalid token address");
        require(_charityAddress != address(0), "Invalid charity address");
        require(_projectAddress != address(0), "Invalid project address");
        oslToken = IERC20(_oslToken);
        charityAddress = _charityAddress;
        projectAddress = _projectAddress;
    }

    function register() external payable nonReentrant {
        require(msg.value == ENTRY_FEE, "Entry must be 1 ETH");
        require(participants.length < MAX_PLAYERS, "Lottery is full");
        require(!isRegistered[msg.sender], "Already registered");
        uint256 reward = calculateReward(PLAYER_REWARD);
        require(_availableRewardReserve() >= reward, "Not enough OSL rewards");
        isRegistered[msg.sender] = true;
        participants.push(msg.sender);
        require(oslToken.transfer(msg.sender, reward), "OSL reward failed");
    }

    function selectWinner(uint256 randomNumber) external nonReentrant {
        require(participants.length == MAX_PLAYERS, "Need 3 participants");
        uint256 winnerIndex = randomNumber % MAX_PLAYERS;
        address payable winner = payable(participants[winnerIndex]);
        lastWinner = winner;

        uint256 bonus = calculateReward(WINNER_BONUS);
        require(_availableRewardReserve() >= bonus, "Not enough OSL for winner");
        require(oslToken.transfer(winner, bonus), "Winner OSL reward failed");

        uint256 pool = address(this).balance;
        uint256 winnerShare = (pool * 95) / 100;
        uint256 charityShare = (pool * 3) / 100;
        uint256 projectShare = pool - winnerShare - charityShare;
        winner.transfer(winnerShare);
        charityAddress.transfer(charityShare);
        projectAddress.transfer(projectShare);

        for (uint256 i = 0; i < participants.length; i++) isRegistered[participants[i]] = false;
        delete participants;
        drawingCount++;
    }

    function registerExclusive() external nonReentrant {
        require(oslPriceUSD > 1 ether, "Exclusive Draw closed");
        require(exclusiveParticipants.length < MAX_PLAYERS, "Exclusive Draw full");
        require(!isExclusiveRegistered[msg.sender], "Already registered");
        require(oslToken.transferFrom(msg.sender, address(this), EXCLUSIVE_ENTRY_FEE), "OSL transferFrom failed");
        isExclusiveRegistered[msg.sender] = true;
        exclusiveParticipants.push(msg.sender);
        exclusivePool += EXCLUSIVE_ENTRY_FEE;
    }

    function selectExclusiveWinner(uint256 randomNumber) external nonReentrant {
        require(exclusiveParticipants.length == MAX_PLAYERS, "Need 3 exclusive participants");
        require(exclusivePool == EXCLUSIVE_ENTRY_FEE * MAX_PLAYERS, "Invalid exclusive pool");
        uint256 winnerIndex = randomNumber % MAX_PLAYERS;
        address winner = exclusiveParticipants[winnerIndex];
        lastExclusiveWinner = winner;

        uint256 pool = exclusivePool;
        uint256 winnerShare = (pool * 95) / 100;
        uint256 charityShare = (pool * 3) / 100;
        uint256 projectShare = pool - winnerShare - charityShare;

        exclusivePool = 0;
        for (uint256 i = 0; i < exclusiveParticipants.length; i++) isExclusiveRegistered[exclusiveParticipants[i]] = false;
        delete exclusiveParticipants;
        exclusiveDrawingCount++;

        require(oslToken.transfer(winner, winnerShare), "Winner OSL payout failed");
        require(oslToken.transfer(charityAddress, charityShare), "Charity OSL payout failed");
        require(oslToken.transfer(projectAddress, projectShare), "Project OSL payout failed");
    }

    function calculateReward(uint256 baseReward) public view returns (uint256) {
        if (oslPriceUSD <= 1 ether) return baseReward;
        return (baseReward * 1 ether) / oslPriceUSD;
    }

    function setOSLPriceUSD(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be greater than zero");
        oslPriceUSD = newPrice;
    }

    function setAddresses(address payable _charity, address payable _project) external onlyOwner {
        require(_charity != address(0) && _project != address(0), "Invalid address");
        charityAddress = _charity;
        projectAddress = _project;
    }

    function getNumParticipants() external view returns (uint256) { return participants.length; }
    function getExclusiveNumParticipants() external view returns (uint256) { return exclusiveParticipants.length; }
    function getLotteryOSLBalance() external view returns (uint256) { return oslToken.balanceOf(address(this)); }
    function getAvailableRewardReserve() external view returns (uint256) { return _availableRewardReserve(); }

    function _availableRewardReserve() internal view returns (uint256) {
        uint256 bal = oslToken.balanceOf(address(this));
        if (bal <= exclusivePool) return 0;
        return bal - exclusivePool;
    }

    receive() external payable {}
}
