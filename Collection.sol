// SPDX-License-Identifier: MIT

// this import helps interact with interfaces that allow the smart contract to have an owner 
// and other owner related functionalities
// it essentially helps us determine who has the access to what in this smart contract
import "@openzeppelin/contracts/access/Ownable.sol";

// this import helps interact with the base ERC721 smart contract
// that allows us to utilize the interfaces already present in the default implementation of
// ERC721, which is the set of rules governing the creation of NFT's as a digital collectible
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

pragma solidity ^0.8.4;

contract Collection is ERC721Enumerable, Ownable {
    // the variables below are standardized to be holding essential information such as
    // the maximum supply of NFT's , the maximum amount of NFT's we can mint at a time
    // and if we ever want to pause minting of NFT's it allows us to do that as well
    
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply = 100000;
    uint256 public maxMintAmount = 5;
    bool public paused = false;

    // creating the name of our own NFT collection and defining its symbol
    constructor() ERC721("DAPP Collection", "DAPP") {}

    // this function defines the ipfs link that specifies the location of our NFT's
    function _baseURI() internal view virtual override returns (string memory) {
    return "ipfs://QmYB5uWZqfunBq7yWnamTqoXWBAHiQoirNLmuxMzDThHhi/";

    }
    
    // this function is where most of the minting capabilites are implemented
    function mint(address _to, uint256 _mintAmount) public payable {
            uint256 supply = totalSupply();
            // the reverts below help verify the minting process to be legitimate
            require(!paused, "The minting is frozen");   // if we are not frozen in our minting process
            require(_mintAmount > 0);   
            require(_mintAmount <= maxMintAmount);
            require(supply + _mintAmount <= maxSupply,"Supply limit exceeded"); // must not exceed the maximum allowable NFT supply
            // this code is implementing the minting from the ERC721Enumerable interface
            for (uint256 i = 1; i <= _mintAmount; i++) {
                _safeMint(_to, supply + i); //  minting the NFT's to the '_to' address specified 
            }
    }

        // this function helps determine the token ID's of already issued NFT's in the owner's wallet
        function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
        {
            uint256 ownerTokenCount = balanceOf(_owner); // finding number of tokens in the owners wallet
            uint256[] memory tokenIds = new uint256[](ownerTokenCount);
            // iterating and finding out the tokens one by one from the owner's token wallet
            for (uint256 i; i < ownerTokenCount; i++) {
                tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return tokenIds;
        }
    
        // the function below is the standardized implementation of the token URI's
        // that have to be specified for the tokens to be issued.
        // it tells the contract what to do with the base URI
        function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory) {
            require(
                _exists(tokenId),
                "ERC721Metadata: URI query for nonexistent token"
                );
                
                string memory currentBaseURI = _baseURI();
                return
                bytes(currentBaseURI).length > 0 
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
        }

        // The functions below are only able to be accessed by the owner of this contract
        // and they provide priviliges that only the owner is able to enjoy
        
        function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
            maxMintAmount = _newmaxMintAmount; // set a new minting amount
        }
        
        function setBaseURI(string memory _newBaseURI) public onlyOwner() {
            baseURI = _newBaseURI; // set a new base URI
        }
        
        function setBaseExtension(string memory _newBaseExtension) public onlyOwner() {
            baseExtension = _newBaseExtension; // set a new extenstion which is the format in which your NFT's are stored
        }
        
        function pause(bool _state) public onlyOwner() {
            paused = _state; // freeze the current minting process 
        }
        
        function withdraw() public payable onlyOwner() {
            require(payable(msg.sender).send(address(this).balance)); // withdraw all the funds in the current contract wallet
                                                                      // into the owners wallet
        }
}
