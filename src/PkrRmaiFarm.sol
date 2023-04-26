//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
pragma abicoder v2;

// import "../lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

// TODO: fix block.timestamp with value 0
contract PkrRmaiFarm is Ownable {
    // using SafeERC20 for IERC20 ;
    address constant PKR_ADDRESS = 0x3993E7F16ED9B0c081bdb0A8812d6f3AaC63C74A;
    // address constant PKR_FARM_ADDRESS = 0x928da6426bC79254b4C7A0AFD6aFB1C6E17ac83E ;
    address constant RMAI_ADDRESS = 0x5416f06830C7826A2ee774c53a3589e707269AB3;
    address constant MATIC_ADDRESS = 0xCC42724C6683B7E57334c4E856f4c9965ED682bD;

    address depositAddress = address(this);

    IERC20 public PKR = IERC20(address(PKR_ADDRESS));
    IERC20 public RMAI = IERC20(address(RMAI_ADDRESS));
    IERC20 public MATIC = IERC20(address(MATIC_ADDRESS));

    event DepositPool(
        address indexed rewardAddress,
        address indexed pkrAddress,
        address indexed rmaiAddress,
        uint256 amount
    );

    event DepositFarm(
        address indexed rewardAddress,
        address indexed pkrAddress,
        address indexed rmaiAddress,
        uint256 amount
    );

    event Reward(
        address rewardAddress,
        uint256 rewardBlock,
        uint256 rewardAmount
    );

    struct User {
        uint256 poolAmount;
        uint256 farmAmount;
        uint256 poolDepositBlock;
        uint256 farmDepositBlock;
        bool exist;
    }
    /// @dev address represent rewardAddress to receive matic tokens
    mapping(address => User) public users; // map rewardAddress to user data ;

    /// pool/farm data
    uint256 poolAmount;
    uint256 farmAmount;
    uint256 poolRewardPerBlock;
    uint256 farmRewardPerBlock;
    uint256 minLockBlocks;

    function poolDeposit(
        address _rewardAddress,
        address _pkrAddress,
        address _rmaiAddress,
        uint256 _amount
    ) external {
        /// check preconditions
        // check correctness of reward address(wallet exist,different from 0,and can receive matic)
        // check equal of pkr & rmai accounts
        // check equal amount of pkr & rmai deposited
        // use approve contract to authorize founds withdraw
        _createUserIfNotExist({
            _rewardAddress: _rewardAddress,
            _poolAmount: _amount,
            _farmAmount: 0,
            _poolDepositBlock: block.timestamp,
            _farmDepositBlock: 0
        });

        _deposit(_pkrAddress, _rmaiAddress, _amount);
        users[_rewardAddress].poolAmount += _amount;
        poolAmount += _amount;

        /// check postconditions
        emit DepositPool(_rewardAddress, _pkrAddress, _rmaiAddress, _amount);
    }

    function farmDeposit(
        address _rewardAddress,
        address _pkrAddress,
        address _rmaiAddress,
        uint256 _amount
    ) external {
        /// check preconditions
        _createUserIfNotExist({
            _rewardAddress: _rewardAddress,
            _poolAmount: 0,
            _farmAmount: _amount,
            _poolDepositBlock: 0,
            _farmDepositBlock: block.timestamp
        });

        _deposit(_pkrAddress, _rmaiAddress, _amount);
        users[_rewardAddress].farmAmount += _amount;
        farmAmount += _amount;

        /// check postconditions
        emit DepositFarm(_rewardAddress, _pkrAddress, _rmaiAddress, _amount);
    }

    /**
     * @notice give to the user posibility to extract from pool deposited liquidity
     */
    function poolExtract() external {
        /*code */
    }

    /**
     * @notice give to the user posibility to extract from farm deposited liquidity
     */
    function farmExtract() external {
        /*code */
    }

    /**
     * @notice claim user accumulated reward
     */
    function claimReward() external {
        /// preconditions
        // verify signed msg
        address rewardAddress = _msgSender();
        User memory user = users[rewardAddress];

        require(block.number > user.poolDepositBlock + minLockBlocks);
        require(block.number > user.farmDepositBlock + minLockBlocks);

        uint256 rewardAmount = _calcReward(rewardAddress);

        /// update user reward / restart reward calculations
        SafeERC20.safeTransferFrom(
            MATIC,
            depositAddress,
            rewardAddress,
            rewardAmount
        );
        users[rewardAddress].exist = false;
        delete users[rewardAddress];

        /// postconditions
    }

    /**
     * @notice return user expected reward according to deposited assets
     */
    function getReward() external view returns (uint256) {
        address rewardAddress = _msgSender();
        return _calcReward(rewardAddress);
    }

    /**
     * @notice calculate user expected reward according to deposited assets
     */
    function _calcReward(address _rewardAddress)
        private
        view
        returns (uint256)
    {
        User memory user = users[_rewardAddress];
        require(user.exist, "user not exist");

        uint256 poolReward = _calcPoolReward(user);
        uint256 farmReward = _calcFarmReward(user);

        return poolReward + farmReward;
    }

    /**
     * @notice calculate user expected reward according to assets deposited in pool
     */
    function _calcPoolReward(User memory _user) private view returns (uint256) {
        uint256 amount = _user.poolAmount / poolAmount;
        uint256 reward = (block.number - _user.poolDepositBlock) *
            poolRewardPerBlock;
        return amount * reward;
    }

    /**
     * @notice calculate user expected reward according to assets deposited in farm
     */
    function _calcFarmReward(User memory _user) private view returns (uint256) {
        uint256 amount = _user.farmAmount / farmAmount;
        uint256 reward = (block.number - _user.farmDepositBlock) *
            farmRewardPerBlock;
        return amount * reward;
    }

    function _createUserIfNotExist(
        address _rewardAddress,
        uint256 _poolAmount,
        uint256 _farmAmount,
        uint256 _poolDepositBlock,
        uint256 _farmDepositBlock
    ) private {
        if (!users[_rewardAddress].exist) {
            users[_rewardAddress] = User({
                poolAmount: _poolAmount,
                farmAmount: _farmAmount,
                poolDepositBlock: _poolDepositBlock,
                farmDepositBlock: _farmDepositBlock,
                exist: true
            });
        }
    }

    function _deposit(
        address _pkrAddress,
        address _rmaiAddress,
        uint256 _amount
    ) private {
        SafeERC20.safeTransferFrom(PKR, _pkrAddress, depositAddress, _amount);
        SafeERC20.safeTransferFrom(RMAI, _rmaiAddress, depositAddress, _amount);
    }
}
