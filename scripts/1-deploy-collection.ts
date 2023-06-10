import ora from 'ora';
import prompts from 'prompts';

async function main() {
  const spinner = ora();
  const json = {
    "type": "Basic NFT",
    "name": "VID",
    "description": "Venom IDentities (VID) serve as secure and easy-to-use domain names for managing your online presence. Venom IDentities (VID) are user-friendly solution to streamline your virtual identity management on the Venom blockchain. With VID, you can easily assign human-readable names to your blockchain and non-blockchain resources, such as Venom and Ethereum addresses, Social Media handles, website URLs, and more. VID enables these resources to be effectively managed and accessed via one, simple name.",
    "preview": {
      "source": "https://ipfs.io/ipfs/QmUvfedgHDXdiMsq5nfLPGLQrR4QAYXHzR5SETBZQ6RGyd",
      "mimetype": "image/svg"
    },
    "files": [
      {
        "source": "https://ipfs.io/ipfs/QmUvfedgHDXdiMsq5nfLPGLQrR4QAYXHzR5SETBZQ6RGyd",
        "mimetype": "image/svg"
      }
    ],
    "external_url": "https://venomid.network"
  };
  const response = await prompts([
    {
        type: 'text',
        name: 'ownerPubkey',
        message: 'Owner key',
        initial: "4bc69a8c3889adee39f6f1e3b2353c86f960c9b835e93397a2015a62a4823765"
    },
  ]);
  spinner.start(`Deploy Collection`);
  try {
    const Nft = await locklift.factory.getContractArtifacts("Nft");
    const Index = await locklift.factory.getContractArtifacts("Index");
    const IndexBasis = await locklift.factory.getContractArtifacts("IndexBasis");
    const signer = (await locklift.keystore.getSigner("0"))!;
    const { contract: collection, tx } = await locklift.factory.deployContract({
      contract: "Collection",
      publicKey: signer.publicKey,
      initParams: {},
      constructorParams: {
        codeNft: Nft.code,
        codeIndex: Index.code,
        codeIndexBasis: IndexBasis.code,
        ownerPubkey: `0x` + response.ownerPubkey,
        json: JSON.stringify(json),
        mintingFee: 100000000
      },
     value: locklift.utils.toNano(2),
    });
    spinner.succeed(`Deploy Collection`);
    console.log(`Collection deployed at: ${collection.address.toString()}`);
  }
  catch(err) {
    spinner.fail(`Failed`);
    console.log(err);
  }
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.log(e);
    process.exit(1);
  });