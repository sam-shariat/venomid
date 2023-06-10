pragma ton-solidity = 0.58.1;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;


import '@itgold/everscale-tip/contracts/TIP4_1/TIP4_1Nft.sol';
import '@itgold/everscale-tip/contracts/TIP4_2/TIP4_2Nft.sol';
import '@itgold/everscale-tip/contracts/TIP4_3/TIP4_3Nft.sol';
import './interfaces/ITokenBurned.sol';
import './abstract/GameManager.sol';
import './libraries/JSONAttributes.sol';

contract Nft is TIP4_1Nft, TIP4_2Nft, TIP4_3Nft, GameManager {

    /// @notice Test game params for json attribute
    string _btcAddress;
    string _ethAddress;
    string _name;
    string _data;
    uint256 _length;

    constructor(
        address owner,
        address gameManager,
        address sendGasTo,
        uint128 remainOnNft,
        string name,
        string json,
        uint128 indexDeployValue,
        uint128 indexDestroyValue,
        TvmCell codeIndex
    ) TIP4_1Nft(
        owner,
        sendGasTo,
        remainOnNft
    ) TIP4_2Nft (
        json
    ) TIP4_3Nft (
        indexDeployValue,
        indexDestroyValue,
        codeIndex
    ) GameManager (
        gameManager
    )
    public {
        tvm.accept();
        _name = name;
        _length = bytes(name).length;
    }

    /// See interfaces/ITIP4_2JSON_Metadata.sol
    function getJson() external view override responsible returns (string json) {
        return {value: 0, flag: 64, bounce: false} (
            /// @dev Add attributes from contract storage to json
            /// Use JSONAttributes library to build json with dynamic attributes
            JSONAttributes.buildAdd(
                /// @dev Defualt `Nft` json
                _json,
                [
                    /// @dev Array of attribute types
                    ATTRIBUTE_TYPE.STRING,
                    ATTRIBUTE_TYPE.ANY
                ],
                [
                    /// @dev Array of attribute `trait_type`
                    "DATA",
                    "LENGTH"
                ],
                [
                    /// @dev Array of attribute `value`
                    /// All data must be formatted into a string
                    _data,
                    format("{}",_length)
                    
                ]
            )
        );
    }


    /// @notice Function for set `_data` attribute
    /// @param data New value for `_data`
    function setData(string data) external onlyGameManager metadataAccess(true) {
        tvm.rawReserve(0, 4);
        _data = data;
        msg.sender.transfer({
            value: 0,
            flag: 128 + 2,
            bounce: false
        });
    }

    /// @notice Getter for `_data`
    /// @return data Value of '_data' attribute
    function getData() external responsible view returns(string data) {
        return{
            value: 0,
            flag: 64,
            bounce: false
        }(_data);
    }

    /// @notice Getter for `_length`
    /// @return length Value of '_length' attribute
    function getLength() external responsible view returns(uint256 length) {
        return{
            value: 0,
            flag: 64,
            bounce: false
        }(_length);
    }

    function _beforeTransfer(
        address to, 
        address sendGasTo, 
        mapping(address => CallbackParams) callbacks
    ) internal virtual override(TIP4_1Nft, TIP4_3Nft) {
        TIP4_3Nft._beforeTransfer(to, sendGasTo, callbacks);
    }   

    function _afterTransfer(
        address to, 
        address sendGasTo, 
        mapping(address => CallbackParams) callbacks
    ) internal virtual override(TIP4_1Nft, TIP4_3Nft) {
        TIP4_3Nft._afterTransfer(to, sendGasTo, callbacks);
    }   

    function _beforeChangeOwner(
        address oldOwner, 
        address newOwner,
        address sendGasTo, 
        mapping(address => CallbackParams) callbacks
    ) internal virtual override(TIP4_1Nft, TIP4_3Nft) {
        TIP4_3Nft._beforeChangeOwner(oldOwner, newOwner, sendGasTo, callbacks);
    }   

    function _afterChangeOwner(
        address oldOwner, 
        address newOwner,
        address sendGasTo, 
        mapping(address => CallbackParams) callbacks
    ) internal virtual override(TIP4_1Nft, TIP4_3Nft) {
        TIP4_3Nft._afterChangeOwner(oldOwner, newOwner, sendGasTo, callbacks);
    }

    function burn(address dest) external virtual onlyManager {
        tvm.accept();
        ITokenBurned(_collection).onTokenBurned(_id, _owner, _manager);
        selfdestruct(dest);
    }

}