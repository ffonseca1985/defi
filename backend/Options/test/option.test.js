const assert = require('assert');
const ganache = require('ganache-cli');
const { describe } = require('mocha');
const { stringify } = require('querystring');
const Web3 = require('web3');

const web3 = new Web3(ganache.provider());

const {call, put } = require('../compile');

const callArtefacts = {interface: call.abi, bytecode: call.evm.bytecode.object};
const putArtefacts = {interface: put.abi, bytecode: put.evm.bytecode.object};

let accounts;
let callContract;

beforeEach(async () => {

     //Get List all Accounts
     accounts = await web3.eth.getAccounts();
     
     //Use one of those accounts to deploy
     //the contract
     callContract = await new web3.eth.Contract(callArtefacts.interface)
          .deploy({data: callArtefacts.bytecode,  arguments: []}).
          send({from: accounts[0], gas: '1000000'});

});

describe('call', () => {
     
     it('accounts', () => {
          console.log(`Account => ${accounts[0]}`);
     });

     it('deploy Contracts', () => {
          console.log(callContract);
          assert.ok(callContract.options.address);
     });
});

