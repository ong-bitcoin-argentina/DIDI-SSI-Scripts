require("dotenv").config();
const { BlockchainManager } = require('@proyecto-didi/didi-blockchain-manager')

const {
  RSK_PROVIDER, // URL RSK BLOCKCHAIN (Testnet para qa, Mainnet para alpha)
  RSK_ETHR_DID_REGISTRY, // 0xdca7ef03e98e0dc2b855be647c39abe984fcf21b
  DID, // Nuevo did de DIDI SERVER -> Ejemplo: did:ethr:0x4ef2e530e06d05c2b9b23e7df9393679881ddddb
  PRIVATE_KEY, // Clave privada correspondiente al did anterior. Ejemplo: f78fe4...
} = process.env;

const providerConfig = {
  networks: [
    {
      name: "",
      rpcUrl: RSK_PROVIDER,
      registry: RSK_ETHR_DID_REGISTRY,
    },
    {
      name: "rsk",
      rpcUrl: RSK_PROVIDER,
      registry: RSK_ETHR_DID_REGISTRY,
    },
  ],
};

console.log(providerConfig)

const DIDIIdentity = {
  did: DID,
  privateKey: PRIVATE_KEY,
};
console.log('using Identity', DIDIIdentity)

// Cambiar estos issuers por los de ALPHA (Estan en dev-team en Slack, o en MongoDB)
const issuersDelegados = [{
  "_id": {
    "$oid": "629634f1d82a4c61378532f8"
  },
  "name": "Emisor CU Test-A9",
  "did": "did:ethr:0xd8b76caa9615739bb60e3ade30a6222a9a49fff1",
  "description": "Emisor CU Test-A9"
},{
  "_id": {
    "$oid": "62965203d82a4c168785337c"
  },
  "name": "Emisor SM Test",
  "did": "did:ethr:0x8407b8568666917d26394abbe89dd191b9dd2ecb",
  "description": "Emisor SM Test"
},{
  "_id": {
    "$oid": "629e918bd82a4c3c688556c8"
  },
  "name": "Coopsol Issuer QA",
  "did": "did:ethr:0x0cfe20f9ab404b128b79359b52dc75cef432205c",
  "description": "Coopsol issuer Issuer"
},{
  "_id": {
    "$oid": "629f8aa1d82a4c9ea7855b0b"
  },
  "name": "Issuer Name",
  "did": "did:ethr:0x9a3be78001f41afd9ce8b6abd1af77fd4948d47a",
  "description": "Descripcion del issuer"
},{
  "_id": {
    "$oid": "629f8aa3d82a4c2bd5855b12"
  },
  "name": "Issuer Name",
  "did": "did:ethr:0xe40fcd09a248124306e31e4162b329cec4f1c7cf",
  "description": "Descripcion del issuer"
},{
  "_id": {
    "$oid": "62a0042ed82a4c7725855d31"
  },
  "name": "Firulais",
  "did": "did:ethr:0x0175b389e3fcde5f235a2495f59c2a92ed725377",
  "description": "Emisor de perros bravos"
},{
  "_id": {
    "$oid": "62a275d2d82a4c1a7e856812"
  },
  "name": "Coopsol QA LACCHAIN",
  "did": "did:ethr:0x8a9a3470ab2151bf82e52f1ea15c178da55becc9",
  "description": "Coopsol QA LACCHAIN"
},{
  "_id": {
    "$oid": "62a275fad82a4c4bae856819"
  },
  "name": "Coopsol QA - RSK",
  "did": "did:ethr:0x680a090e82ebc16dd8e9ce2d476d9624db7155a6",
  "description": "Coopsol QA RSK"
},{
  "_id": {
    "$oid": "62ab9566d82a4c025d858f6a"
  },
  "name": "Firulais",
  "did": "did:ethr:0x0175b389e3fcde5f235a2495f59c2a92ed725666",
  "description": "Emisor de perros bravos"
},{
  "_id": {
    "$oid": "62b0ec9bf517295d26a5f1fe"
  },
  "name": "DIDI Server QA",
  "did": "did:ethr:0x18a208fdf867348db23e3bde3d1e3ab4cf60f9e9",
  "description": "DIDI Server QA"
},{
  "_id": {
    "$oid": "62b0f244f517292dbca5f227"
  },
  "name": "DIDI Issuer QA",
  "did": "did:ethr:0x655e8c5f8413ec3c10be266a51359a91875232b9",
  "description": "DIDI Issuer QA"
},{
  "_id": {
    "$oid": "62b0f2b8f51729b9d9a5f232"
  },
  "name": "Semillas Issuer QA",
  "did": "did:ethr:0xd78a9ca7f731bdd683729a10d42106e2dcce7a48",
  "description": "Semillas Issuer QA"
},{
  "_id": {
    "$oid": "62b0f328f51729c818a5f23e"
  },
  "name": "Test Issuer",
  "did": "did:ethr:0xd2feccfb4cfd53b89e35a70827a5fff4824fa31c",
  "description": "Test Issuer"
},{
  "_id": {
    "$oid": "62b0f678f517292531a5f269"
  },
  "name": "ACDI Issuer",
  "did": "did:ethr:0xa7689f4dd31abc015206cff1bcc75fa5eabfccd4",
  "description": "ACDI Issuer"
},{
  "_id": {
    "$oid": "62b48abb243ccb2a8dd9ef16"
  },
  "name": "Emisor BlockBus - No Borrar",
  "did": "did:ethr:0x942abb27df4e2ea7c5cc168bc97048de68071a42",
  "description": "Emisor Block "
},{
  "_id": {
    "$oid": "62b48c3cf51729be22a602e9"
  },
  "name": "Emisor BlockBus - No Borrar",
  "did": "did:ethr:0x4fab9ea3dfde91e64fca5f355f91cee4105ff0c4",
  "description": "Emisor Block "
},{
  "_id": {
    "$oid": "62d15cfff517291e23a67dfd"
  },
  "name": "Prueba select",
  "did": "did:ethr:0x6617fcb22ae30657cff11a6f9cdfe4002bae161d",
  "description": "Prueba"
}]

const run = async () => {
  const blockchainManager = new BlockchainManager({providerConfig});
  const promises = issuersDelegados.map(({ did }) => blockchainManager.addDelegate(
      DIDIIdentity,
      did,
      "93312000"
    )
  )

  const txs = await Promise.allSettled(promises)
  console.log(JSON.stringify(txs))
  verify()
}


const verify = async () => {
  const blockchainManager = new BlockchainManager({providerConfig});
  const promises = issuersDelegados.map(({ did }) => blockchainManager.validDelegate(
      DIDIIdentity.did,
      did
    )
  )

  const txs = await Promise.allSettled(promises)

  txs.forEach((tx,i)=> {
    console.log(`${issuersDelegados[i].name}(${issuersDelegados[i].did}): ${tx.value}`)  
  })
}

// verify()
run()
