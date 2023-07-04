// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// this import helps interact with interfaces that allow the smart contract to have an owner 
// and other owner related functionalities
// it essentially helps us determine who has the access to what in this smart contract
import "@openzeppelin/contracts/access/Ownable.sol";

// this import helps interact with the base ERC20 smart contract
// that allows us to utilize the interfaces already present in the default implementation of
// ERC20, which is the set of rules governing the creation of our own tokens
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// this import adds and extra layer of functionalities which allow us to be able
// to burn any unneccessary ERC20 tokens
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";


contract ERC20Rewards is ERC20, ERC20Burnable, Ownable {

  mapping(address => bool) controllers; // keeping tabs on who can be the present controller to
                                        // be able to access the NFT staking smart contract.
  
  //defining our own name and symbol for the ERC20 tokens
  constructor() ERC20("ERC20Rewards", "ERC20R") { }

  // this function allows us to mint the tokens that we create such that they are available on
  // the blockchain and have significance
  // sends the tokens to the end user directly rather than sending it to the staking smart contract
  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    // amount here is the amount already calculated, which is required to be sent to the end user
    _mint(to, amount); // using pre existing minting capabilities in the ERC20 smart contract we imported
  }

  // this function is relevant if we do not specify the capped amount of the number of tokens
  // if we are allowing tokens to inflate, we can call this token to burn the said tokens
  function burnFrom(address account, uint256 amount) public override {
      if (controllers[msg.sender]) {
          _burn(account, amount);
      }
      else {
          super.burnFrom(account, amount);
      }
  }

  // the functions below can only be called by owners of this contract

  function addController(address controller) external onlyOwner {
    // update the smart contract with the address allowed to be acting as the controller
    // limits who can use minting and other functionalities
    controllers[controller] = true;
  }

  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
}
