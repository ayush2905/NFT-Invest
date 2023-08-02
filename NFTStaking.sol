// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// we are importing the solidity files already written for the ERC20 token rewards that we're going to issue
import "./ERC20Rewards.sol";

// importing the collection for the smart contract which holds the NFT collection
import "./Collection.sol";

// IERC721Receiver is the interface allowing us to send and receive the NFT's into our smart contract
contract NFTStaking is Ownable, IERC721Receiver {

  uint256 public totalStaked; // total amount of NFT's staked by the user
  
  // struct to store a stake's token, owner, and earning values 
  struct Stake {
    uint24 tokenId;
    uint48 timestamp;
    address owner;
  }

  // these two events are triggered by the presence of the three variables :-
  // owner - which specifies the owner of the smart contract 
  // tokenId - which specifies the token ID for the NFT
  // value - specifies a particular value on the NFT
  event NFTStaked(address owner, uint256 tokenId, uint256 value);
  event NFTUnstaked(address owner, uint256 tokenId, uint256 value);

  // this event is triggered from the owner and the amount variable
  // amount - this variable specifies the amount of tokens issued to the wallet as the reward
  event Claimed(address owner, uint256 amount);

  // reference to the Block NFT contract
  Collection nft;
  ERC20Rewards token;

  // maps tokenId to stake
  // this mapping is necessary to help determine the various Staking parameters for a particular user
  mapping(uint256 => Stake) public vault; 

   constructor(Collection _nft, ERC20Rewards _token) { 
    nft = _nft;
    token = _token;
  }

  // this function is used to specify the tokenIds of any NFT that the user wants to stake
  function stake(uint256[] calldata tokenIds) external {
    uint256 tokenId;
    totalStaked += tokenIds.length; // number of NFT's staked
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i]; // requiring individual tokenId's to start issuing rewards per token
      require(nft.ownerOf(tokenId) == msg.sender, "not your token"); //ownerOf function imported from ERC721
      require(vault[tokenId].tokenId == 0, "already staked");

      // this is transferring the NFT to the vault that we have created
      nft.transferFrom(msg.sender, address(this), tokenId);
      // block.timestamp is a variable responsible for holding the current time at which the event takes place
      emit NFTStaked(msg.sender, tokenId, block.timestamp);

      // calls the stake constructor and sends the corresponding values
      // this is the staking vault
      vault[tokenId] = Stake({
        owner: msg.sender,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp)
      });
    }
  }

  // allows the user to unstake as many NFT back as they want into the specified account
  function _unstakeMany(address account, uint256[] calldata tokenIds) internal {
    uint256 tokenId;
    totalStaked -= tokenIds.length;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == msg.sender, "not an owner");

      delete vault[tokenId];
      emit NFTUnstaked(account, tokenId, block.timestamp);
      nft.transferFrom(address(this), account, tokenId);
    }
  }

 // the following 3 functions are helper functions used to call _claim() for certain actions
  function claim(uint256[] calldata tokenIds) external {
      _claim(msg.sender, tokenIds, false);
  }

  function claimForAddress(address account, uint256[] calldata tokenIds) external {
      _claim(account, tokenIds, false);
  }

  function unstake(uint256[] calldata tokenIds) external {
      _claim(msg.sender, tokenIds, true);
  }

 // this is the function wherein we calculate the users accumulated ERC20 tokens and then
 // transfer those tokens to the end users wallet
  function _claim(address account, uint256[] calldata tokenIds, bool _unstake) internal {
    uint256 tokenId;
    uint256 earned = 0;

    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == account, "not an owner");

      uint256 stakedAt = staked.timestamp; // finding out the exact time at which the user had staked an NFT
      // formula for calculating the reward for each NFT that the user holds
      earned += 100 ether * ((block.timestamp - stakedAt)^2) / 1 days;
      vault[tokenId] = Stake({
        owner: account,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp)
      });
    }
    // this is for restricting the user from claiming unless a specific amount is earned by the user
    if (earned > 0) {
      earned = earned / 100;
      // actual minting and issuing of the token takes place
      token.mint(account, earned);
    }
    if (_unstake) {
      // if the user wants to unstake simultaneously while claiming they can do so
      _unstakeMany(account, tokenIds);
    }
    emit Claimed(account, earned);
  }

  // if the user ever wants to know through what math are they earning the rewards
  // and how much they can earn per second
  function earningInfo(uint256[] calldata tokenIds) external view returns (uint256[2] memory info) {
     uint256 tokenId;
     uint256 totalScore = 0;
     uint256 earned = 0;
      Stake memory staked = vault[tokenId];
      uint256 stakedAt = staked.timestamp;
      earned += 100 ether * ((block.timestamp - stakedAt)^2) / 1 days;
    uint256 earnRatePerSecond = totalScore * 1 ether / 1 days;
    earnRatePerSecond = earnRatePerSecond / 100;
    // earned, earnRatePerSecond
    return [earned, earnRatePerSecond];
  }

  // providing the user the information about how many NFT's are staked from the wallet
  // which is specified here
  function balanceOf(address account) public view returns (uint256) {
    uint256 balance = 0;
    uint256 supply = nft.totalSupply();
    for(uint i = 1; i <= supply; i++) {
      // making sure that we are showing the balance of the legal tokens only
      // i.e. the account for which we are showing the balance, it should be the owner of the token
      if (vault[i].owner == account) {
        balance += 1;
      }
    }
    return balance;
  }

  // this shows the user how many tokens they have issued in this particular vault
  function tokensOfOwner(address account) public view returns (uint256[] memory ownerTokens) {

    uint256 supply = nft.totalSupply();
    uint256[] memory tmp = new uint256[](supply);

    uint256 index = 0;
    // finding out the particular tokens that a user has in this vault
    for(uint tokenId = 1; tokenId <= supply; tokenId++) {
      if (vault[tokenId].owner == account) {
        tmp[index] = vault[tokenId].tokenId;
        index +=1;
      }
    }
    // storing the tokens earned by the user into the temporary array and then returning to display it 
    uint256[] memory tokens = new uint256[](index);
    for(uint i = 0; i < index; i++) {
      tokens[i] = tmp[i];
    }

    return tokens;
  }

  // this is controller for the way in which we have received the NFT's
  // allows for protection of the way in which we can stake NFT's and nobody can bypass certain stops
  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send nfts to Vault directly");
      return IERC721Receiver.onERC721Received.selector;
    }
  
}
