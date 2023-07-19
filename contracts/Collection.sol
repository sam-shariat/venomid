pragma ton-solidity = 0.58.1;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "@itgold/everscale-tip/contracts/TIP4_2/TIP4_2Collection.sol";
import "@itgold/everscale-tip/contracts/TIP4_3/TIP4_3Collection.sol";
import "@itgold/everscale-tip/contracts/access/OwnableExternal.sol";
import "./interfaces/ITokenBurned.sol";
import "./Nft.sol";

contract VID is TIP4_2Collection, TIP4_3Collection, OwnableExternal, ITokenBurned {
  /**
   * Errors
   **/
  uint8 constant sender_is_not_owner = 101;
  uint8 constant value_is_less_than_required = 102;
  uint8 constant name_can_not_be_less_than_3_words = 103;
  uint8 constant name_already_exists = 104;
  uint8 constant name_invalid = 105;
  uint8 constant nft_invalid = 106;

  /// _remainOnNft - the number of crystals that will remain after the entire mint
  /// process is completed on the Nft contract
  uint128 _remainOnNft = 0.3 ever;

  uint128 _lastTokenId;

  uint128 _mintingFee;

  struct Primary {
    address nftAddress;
    string name;
  }

  struct Name {
    address nftAddress;
    string name;
    address owner;
  }

  mapping(string => Name) names;
  mapping(address => Primary) primaries;

  constructor(
    TvmCell codeNft,
    TvmCell codeIndex,
    TvmCell codeIndexBasis,
    uint256 ownerPubkey,
    string json,
    uint128 mintingFee
  )
    public
    OwnableExternal(ownerPubkey)
    TIP4_1Collection(codeNft)
    TIP4_2Collection(json)
    TIP4_3Collection(codeIndex, codeIndexBasis)
  {
    tvm.accept();
    _mintingFee = mintingFee;
  }

  function mintNft(string json, string name) external virtual {
    require(isValidUsername(name), name_invalid);
    require(!nameExists(name), name_already_exists);
    require(bytes(name).length > 2, name_can_not_be_less_than_3_words);
    require(
      msg.value > _remainOnNft + calculateMintingFee(name) + (2 * _indexDeployValue),
      value_is_less_than_required
    );
    tvm.rawReserve(_mintingFee, 4);

    uint256 id = _lastTokenId;
    _totalSupply++;
    _lastTokenId++;

    TvmCell codeNft = _buildNftCode(address(this));
    TvmCell stateNft = _buildNftState(codeNft, id);
    address nftAddr = new VenomIDNft{ stateInit: stateNft, value: 0, flag: 128 }(
      msg.sender,
      msg.sender,
      msg.sender,
      _remainOnNft,
      name,
      json,
      _indexDeployValue,
      _indexDestroyValue,
      _codeIndex
    );
    names[name] = Name(nftAddr,name,msg.sender);
    if (!primaries.exists(msg.sender)) {
      primaries[msg.sender] = Primary(nftAddr, name);
    }
    emit NftCreated(id, nftAddr, msg.sender, msg.sender, msg.sender);
  }

  function getPrimaryName(address _owner) public view returns (Primary) {
    if (primaries.exists(_owner)) {
      return primaries[_owner];
    } else {
      return Primary(address(0), "");
    }
  }

  function nameExists(string name) public view returns (bool) {
    return names.exists(name);
  }

  function getInfoByName(string name) public view returns (Name) {
    if (nameExists(name)) {
      return names[name];
    } else {
      return Name(address(0),'notfound',address(0));
    }
  }

  function isValidUsername(string name) public view returns (bool) {
    bytes nameBytes = bytes(name);
    if (nameBytes.length <= 2 || nameBytes.length > 32) {
        // Username length should be between 3 and 32 characters
        return false;
    }
    for (uint i = 0; i < nameBytes.length; i++) {
        bytes1 char = nameBytes[i];
        if (    
            !(uint8(char) >= 48 && uint8(char) <= 57) && // 0-9
            !(uint8(char) >= 65 && uint8(char) <= 90) && // A-Z
            !(uint8(char) >= 97 && uint8(char) <= 122) && // a-z
            (char | bytes1(0x20) != bytes1(0x5f))
        ) {
            // Invalid character found in username
            return false;
        }
    }
    // All characters in username are valid 
    return true;
  }

  function calculateMintingFee(string name) public view returns (uint128) {
    if (bytes(name).length == 3) {
      return (_mintingFee + 1) * 9;
    } else if (bytes(name).length == 4) {
      return (_mintingFee + 1) * 6;
    } else if (bytes(name).length == 5) {
      return (_mintingFee + 1) * 3;
    } else if (bytes(name).length == 6) {
      return _mintingFee + 1;
    } else {
      return _mintingFee;
    }
  }

  function setPrimaryName(address _nftAddress, string _name) external virtual {
    tvm.rawReserve(0, 4);
    Name nftInfo = getInfoByName(_name);
    require(nftInfo.owner == msg.sender, sender_is_not_owner);
    require(nftInfo.nftAddress == _nftAddress, nft_invalid);
    primaries[msg.sender] = Primary(_nftAddress, _name);
  }

  function withdraw(address dest, uint128 value) external pure onlyOwner {
    tvm.accept();
    dest.transfer(value, true);
  }

  function onTokenBurned(uint256 id, address owner, address manager) external override {
    require(msg.sender == _resolveNft(id));
    emit NftBurned(id, msg.sender, owner, manager);
    _totalSupply--;
  }

  function setRemainOnNft(uint128 remainOnNft) external virtual onlyOwner {
    _remainOnNft = remainOnNft;
  }

  function setMintingFee(uint128 mintingFee) external virtual onlyOwner {
    _mintingFee = mintingFee;
  }

  function mintingFee() external view responsible returns (uint128) {
    return { value: 0, flag: 64, bounce: false } (_mintingFee);
  }

  function _buildNftState(
    TvmCell code,
    uint256 id
  ) internal pure virtual override(TIP4_2Collection, TIP4_3Collection) returns (TvmCell) {
    return tvm.buildStateInit({ contr: VenomIDNft, varInit: { _id: id }, code: code });
  }
}
