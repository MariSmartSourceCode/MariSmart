# MariSmart

a development and verification framework for maritime transportation smart contracts 

## Development

The MariSmart templates is under /Templates, the architecture of these smart contracts can be seen in the paper.

## Cases

Three sets of MariSmart contracts are implemented for real-world cases, namely IoT, LNG and NFT. Since the contracts are customized from the templates, the templates should be imported to the project.

## Verification

the MariSmart contracts for thee cases is under /Verification, including a property file and three uml models. you can verify them in UPPAAL by the following steps:

> 1. download UPPAAL at https://uppaal.org/downloads/
> 
> 2. run the verification with command ./ bin-Darwin/verifyta [model file] [properties]

## Verifier Usage

- Prepare UPPAAL from https://uppaal.org/downloads/, and move libgcc_s.1.dylib, libstdc++.6.dylib and verifyta under /Verifier/uppaal
- Start the Verifier by run `python3 /Verifier/PromptGenerator.py`
- You can start with ./Verifier/test.sol, with properties provided in /properties
- The Verifier will automatically convert Solidity file to UPPAAL model, and return the result.

![type in source path](https://github.com/MariSmartSourceCode/MariSmart/blob/main/figures/1.png)

![select properties to verify](https://github.com/MariSmartSourceCode/MariSmart/blob/main/figures/2.png)

![return the results](https://github.com/MariSmartSourceCode/MariSmart/blob/main/figures/3.png)



## License

This project is licensed under the MIT license.
