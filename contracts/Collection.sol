pragma ton-solidity =0.58.1;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "@itgold/everscale-tip/contracts/TIP4_2/TIP4_2Collection.sol";
import "@itgold/everscale-tip/contracts/TIP4_3/TIP4_3Collection.sol";
import "@itgold/everscale-tip/contracts/access/OwnableExternal.sol";
import "./interfaces/ITokenBurned.sol";
import "./Nft.sol";

contract Collection is TIP4_2Collection, TIP4_3Collection, OwnableExternal, ITokenBurned {
  /**
   * Errors
   **/
  uint8 constant sender_is_not_owner = 101;
  uint8 constant value_is_less_than_required = 102;
  uint8 constant name_can_not_be_less_than_3_words = 103;
  uint8 constant name_already_exists = 104;

  /// _remainOnNft - the number of crystals that will remain after the entire mint
  /// process is completed on the Nft contract
  uint128 _remainOnNft = 0.3 ever;

  uint128 _lastTokenId;

  uint128 _mintingFee;

  mapping(string => address) names;

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
    require(!nameExists(name), name_already_exists);
    require(bytes(name).length > 2, name_can_not_be_less_than_3_words);
    require(msg.value > _remainOnNft + calculateMintingFee(name) + (2 * _indexDeployValue), value_is_less_than_required);
    tvm.rawReserve(_mintingFee, 4);

    uint256 id = _lastTokenId;
    _totalSupply++;
    _lastTokenId++;

    TvmCell codeNft = _buildNftCode(address(this));
    TvmCell stateNft = _buildNftState(codeNft, id);
    address nftAddr = new Nft{ stateInit: stateNft, value: 0, flag: 128 }(
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
    names[name] = msg.sender;
    emit NftCreated(id, nftAddr, msg.sender, msg.sender, msg.sender);
  }

  function nameExists(string name) public view returns (bool) {
    return names.exists(name);
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
    return tvm.buildStateInit({ contr: Nft, varInit: { _id: id }, code: code });
  }
}
