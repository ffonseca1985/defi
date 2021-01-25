
const path = require('path');
const fs = require('fs');
const solc = require('solc');

const inboxPath = path.resolve(__dirname, 'contracts', 'option.sol');
const source = fs.readFileSync(inboxPath, 'utf8');

var solcInput = {

    language: "Solidity",
    sources: { 
        contract: {
            content: source
        }
     },
    settings: {
        optimizer: {
            enabled: true
        },
        evmVersion: "byzantium",
        outputSelection: {
            "*": {
              "": [
                "legacyAST",
                "ast"
              ],
              "*": [
                "abi",
                "evm.bytecode.object",
                "evm.bytecode.sourceMap",
                "evm.deployedBytecode.object",
                "evm.deployedBytecode.sourceMap",
                "evm.gasEstimates"
              ]
            },
        }
    }
};

solcInput = JSON.stringify(solcInput);
// console.log(solc.compile(solcInput))

var contractObject = solc.compile(solcInput);
//contractObject = JSON.parse(contractObject);

var call = JSON.parse(contractObject).contracts.contract.OptionCall;
var put = JSON.parse(contractObject).contracts.contract.PutCall;
var base = JSON.parse(contractObject).contracts.contract.OptionBase;

module.exports = { call, put, base };