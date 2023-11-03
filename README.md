# MariSmart

a development and verification framework for maritime transportation smart contracts 

** goto 124.16.137.30:50002 for demo, where passcode is attached in the report! **
** 请从 124.16.137.30:50002 访问示例，Chinasoft 工具报告内提供用户名密码！**

## Development

The MariSmart templates is under /Templates, the architecture of these smart templates can be seen in the paper.

X. Zhao, Q. Wei, X.-Y. Zhu, and W. Zhang, “A smart contract  development framework for maritime transportation systems,”  in Proc. Of The IEEE International Workshop on Blockchain  and Smart Contracts (IEEE BSC 2023). IEEE, 2023.

## Cases

We refactor 9 real-world cases into MariSmart contracts, which are under /Cases, with a src.sol for original smart contracts, a standard.sol for refactored ones, and a UPPAAL model as the xml file. 

## Verification

We implemented a automated verifier for MariSmart contracts, the usage of such tool contains the following steps:

1. prepare for UPPAAL. 

> 1. download UPPAAL at https://uppaal.org/downloads/
> 
> 2. move files under bin-Darwin directory to /Verification/Verifier/UPPAAL

2. prepare for requirements. ```pip install -r requirements.txt```

3. start Verifier with commond ```python /Verification/Verifier/PromptGenerator.py [parameters]``` , the parameters are as follows. Note that it's OK if you don't enter any parameters, since CLI will guide you to fill in the necessary ones.

```bash
options:
  -h, --help            show this help message and exit
  -s SOURCE_FILE, --source_file SOURCE_FILE
                        源代码文件或文件夹路径
  -p PROPERTY, --property PROPERTY
                        验证性质，如'1,3,4'或'all'
  -c CUSTOM_PROPERTY, --custom_property CUSTOM_PROPERTY
                        自定义性质
  -u UPPAAL_OUTPUT, --uppaal_output UPPAAL_OUTPUT
                        输出 UPPAAL 模型路径
  -r REPORT_OUTPUT, --report_output REPORT_OUTPUT
                        输出报告路径
```

4. The Verifier will automatically convert Solidity file to UPPAAL model, and return the result. Specifically, the result and time will be print to console, and the counter example will be stored in [casename]_report[timestamp].txt

## Webserver

We provide a web app at 124.16.137.30:50002 for demo.

![type in source path](https://github.com/MariSmartSourceCode/MariSmart/blob/main/figures/1.png)

![select properties to verify](https://github.com/MariSmartSourceCode/MariSmart/blob/main/figures/2.png)

![return the results](https://github.com/MariSmartSourceCode/MariSmart/blob/main/figures/3.png)

## License

This project is licensed under the MIT license.
