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

## License

This project is licensed under the MIT license.
