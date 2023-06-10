# Venom ID Contracts

Venom IDentities (VID) serve as secure and easy-to-use domain names for managing your online presence. Venom IDentities (VID) are user-friendly solution to streamline your virtual identity management on the Venom blockchain. With VID, you can easily assign human-readable names to your blockchain and non-blockchain resources, such as Venom and Ethereum addresses, Social Media handles, website URLs, and more. VID enables these resources to be effectively managed and accessed via one, simple name.

Trust that your virtual identity management is secure, seamless and above all, simple. Experience how everything you are is now accessible with a single click through your customized VID link on the Venom blockchain.
***
### How to use JSONAttributes library to generate dynamic attributes
1. Add custom game params field to your NFT contract:
```solidity
/// @notice Test game params for json attribute
uint32 _points;
string _rarity;
```
2. Import `JSONAttributes` library:
```solidity
import './libraries/JSONAttributes.sol';
```
3. Override default `getJson()` function:
```solidity
/// @notice Attribute types
/// ANY - without quotation marks: uint, int, bool
/// STRING - with quotation marks: string
enum ATTRIBUTE_TYPE {
    ANY,
    STRING
}
```
```solidity
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
                ATTRIBUTE_TYPE.ANY,
                ATTRIBUTE_TYPE.STRING
            ],
            [
                /// @dev Array of attribute `trait_type`
                "Points",
                "Rarity"
            ],
            [
                /// @dev Array of attribute `value`
                /// All data must be formatted into a string
                format("{}", _points),
                _rarity
            ]
        )
    );
}
```
4. Json with dynamic attributes:
```json
{
    "type": "Basic NFT",
    "name": "Sample Name",
    "description": "Hello world!",
    "preview": {
        "source": "https://everscale.network/images/Backgrounds/Main/main-hero.png",
        "mimetype": "image/png"
    },
    "files": [
        {
        "source": "https://everscale.network/images/Backgrounds/Main/main-hero.png",
        "mimetype": "image/png"
        }
    ],
    "external_url": "https://everscale.network",
    "attributes": [
        {
            "trait_type": "Points",
            "value": 200
        },
        {
            "trait_type": "Rarity",
            "value": "Rare"
        }
    ]
}
```
 