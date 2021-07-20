const Web3 = require('web3');
require('dotenv').config();

const rskWeb3 = new Web3(process.env.BLOCKCHAIN_URL_RSK);
const lacchainWeb3 = new Web3(process.env.BLOCKCHAIN_URL_LAC);
const bfaWeb3 = new Web3(process.env.BLOCKCHAIN_URL_BFA);

const accounts = [
  {
    address: process.env.ADDRESS_DIDI_SERVER,
    alias: 'DIDI Server',
  },
  {
    address: process.env.ADDRESS_ISSUER,
    alias: 'Semillas Issuer',
  },
  { 
    address: process.env.ADDRESS_RONDA,
    alias: 'Ronda DID',
  },
  { 
    address: process.env.ADDRESS_RONDA_OWNER,
    alias: 'Ronda SC owner',
  },
  { 
    address: process.env.RONDA_REFILL,
    alias: 'Ronda Refills'
  },
]

const web3Providers = [
  {web3: rskWeb3, blockchainName:'RSK'},
  {web3: lacchainWeb3, blockchainName:'Lacchain'},
  {web3: bfaWeb3, blockchainName:'BFA'},
];

const getTxs = async ({address, alias}, {web3, blockchainName} )=> {
  console.log(address)
  const txs = await web3.eth.getTransactionCount(address);
  console.log(`${alias}: ${txs} en ${blockchainName}`);
}

accounts.forEach((account) => {
  web3Providers.forEach((w) => {
    getTxs(account,w);
  })
})
