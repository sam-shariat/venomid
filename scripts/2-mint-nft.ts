import { Address, zeroAddress } from "locklift/.";
import ora from "ora";
import prompts from "prompts";

async function main() {
  const spinner = ora();
  const name = "samy";
  const image = "https://ipfs.io/ipfs/QmUvfedgHDXdiMsq5nfLPGLQrR4QAYXHzR5SETBZQ6RGyd";
  const json = {
    type: "Basic NFT",
    name: name + ".VID",
    description: name + ".VID, a Venom ID",
    preview: {
      source: image,
      mimetype: "image/svg",
    },
    files: [
      {
        source: image,
        mimetype: "image/svg",
      },
    ],
    external_url: "https://venomid.link/"+name,
  };
  const response = await prompts([
    {
      type: "text",
      name: "collectionAddr",
      message: "Collection address",
      initial: '0:247682756b04b9e2290fd1801bcd7cd9ab5e46a167ff339e3e176355b5db4901',
    },
    {
      type: "text",
      name: "data",
      message: "Data",
      initial: "QmbVfnejQqU71jSN4p5Wc42HFveR479mc62u2xUJwo4M7t",
    },
  ]);
  spinner.start(`Mint Nft`);
  try {
    const signer = (await locklift.keystore.getSigner("0"))!;
    const collection = await locklift.factory.getDeployedContract("Collection", new Address(response.collectionAddr));
    const accountsFactory = await locklift.factory.getAccountsFactory("Wallet");
  
    const { account: account, tx } = await accountsFactory.deployNewAccount({
      publicKey: signer.publicKey,
      initParams: {
        _randomNonce: locklift.utils.getRandomNonce(),
      },
      constructorParams: {},
      value: locklift.utils.toNano(2),
    });

    
    const nameExists = await collection.methods.nameExists({name:name}).call();
    if(nameExists.value0) {
      console.log(nameExists)
      spinner.fail(`Failed, Name already exists`);
      //process.exit(1);
      
    }
    
    
    await account.runTarget(
      {
        contract: collection,
        value: locklift.utils.toNano(1),
      },
      collection =>
        collection.methods.mintNft({
          json: JSON.stringify(json),
          name: name
        }),
    );

    const nftId = await collection.methods.totalSupply({ answerId: 0 }).call();
    const nftAddr = await collection.methods
      .nftAddress({ answerId: 0, id: (Number(nftId.count) - 1).toString() })
      .call();

    const nft = await locklift.factory.getDeployedContract("Nft", new Address(nftAddr.nft.toString()));

    await account.runTarget(
      {
        contract: nft,
        value: locklift.utils.toNano(0.2),
      },
      nft =>
        nft.methods.setData({
          data: response.data,
        }),
    );
    

    const nftJson = await nft.methods.getJson({ answerId: 0 }).call();
    const dataIpfs = await nft.methods.getData({ answerId: 0 }).call();

    spinner.succeed(`Mint Nft`);
    console.log(`Nft minted at: ${nftAddr.nft.toString()}`);
    console.log(`Nft Data: ${dataIpfs.data.toString()}`);
    console.log(`Nft JSON: ${nftJson.json.toString()}`);
  } catch (err) {
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
