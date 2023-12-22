import os

import ContractTranslator as ContractTranslator
import SolidityFileReader as SolidityFileReader
import UppaalFileGenerator as UppaalFileGenerator

source_path = ""
property_set = set()
property_string = ""
custom_property = ""
uppaal_output = ""
report_output = ""


def transform(case):
    root_dir = os.path.dirname(os.path.abspath(__file__))
    # source_path = os.path.join(root_dir, 'test.sol')
    source_path = os.path.join(root_dir, '../../Cases/%s/standard.sol' % case)
    uppaal_output = source_path.replace('standard.sol', 'output.xml')
    reader = SolidityFileReader.SolidityFileReader(source_path)
    translator = ContractTranslator.ContractTranslator(reader)
    system = translator.translate()
    UppaalFileGenerator.generate(system, uppaal_output)


if __name__ == '__main__':
    transform('IoT')
