from prompt_toolkit import prompt
from prompt_toolkit.styles import Style
from prompt_toolkit.shortcuts import ProgressBar
from prompt_toolkit.formatted_text import HTML
import time
from argparse import RawTextHelpFormatter
import argparse
import subprocess
import os
import tabulate
import re
import json

import ContractTranslator as ContractTranslator
import SolidityFileReader as SolidityFileReader
import UppaalFileGenerator as UppaalFileGenerator

# https://python-prompt-toolkit.readthedocs.io/en/stable/pages/progress_bars.html
welcome_str = '======================================================\n\
    __  ___           _ _____                      __  \n\
   /  |/  /___ ______(_) ___/____ ___  ____ ______/ /_ \n\
  / /|_/ / __ `/ ___/ /\__ \/ __ `__ \/ __ `/ ___/ __/ \n\
 / /  / / /_/ / /  / /___/ / / / / / / /_/ / /  / /_   \n\
/_/  /_/\__,_/_/  /_//____/_/ /_/ /_/\__,_/_/   \__/   \n\
=======================================================\n\
欢迎使用 MariSmart：一款海洋运输智能合约自动验证工具！            \n\
v 1.0'

source_path = ""
property_set = set()
property_string = ""
custom_property = ""
uppaal_output = ""
report_output = ""


def bottom_toolbar_1():
    return [('class:bottom-toolbar', '请输入合约源码路径，或输入quit退出')]


def bottom_toolbar_2():
    return [('class:bottom-toolbar', '请输入需要验证的性质，如1,2,3或all，或输入quit退出')]


def bottom_toolbar_3():
    return [('class:bottom-toolbar', '请输入自定义性质，或输入quit退出')]


style = Style.from_dict({
    'bottom-toolbar': '#ffffff bg:#333333',
})


if __name__ == '__main__':
    root_dir = os.path.dirname(os.path.abspath(__file__))
    translate_flag = False
    picked_flag = False
    parser = argparse.ArgumentParser(
        formatter_class=RawTextHelpFormatter, prog='MariSmart', description=welcome_str)
    parser.add_argument('-s', "--source_file", default='', help='源代码文件或文件夹路径')
    parser.add_argument('-p', "--property", default='',
                        help='验证性质，如\'1,3,4\'或\'all\'')
    parser.add_argument('-c', "--custom_property", default='', help='自定义性质')
    parser.add_argument('-u', "--uppaal_output",
                        default='', help='输出 UPPAAL 模型路径')
    parser.add_argument('-r', "--report_output", default='', help='输出报告路径')
    parser.add_argument('-t', "--test_case", default='',
                        help='验证测试用例,如 IoT, ShipChain, NFT1, NFT2')
    args = parser.parse_args()
    parser.print_help()

    source_path = args.source_file
    property_string = args.property
    custom_property = args.custom_property

    if uppaal_output == '':
        uppaal_output = source_path.replace(".sol", '.xml')
    else:
        uppaal_output = args.uppaal_output

    if args.test_case != '':
        uppaal_output = '%s/../Cases/%s/%s.xml' % (
            root_dir, args.test_case, args.test_case)
        property_string = 'all'
        translate_flag = True
    if report_output == '':
        report_output = uppaal_output.replace(
            ".xml", '_report%s.txt' % time.strftime("%Y%m%d%H%M%S", time.gmtime()))
    else:
        report_output = args.report_output
    while True:
        if not translate_flag:
            if source_path == '':
                source_path = prompt(
                    'cmd>', bottom_toolbar=bottom_toolbar_1, style=style)
                if source_path == 'quit':
                    break
                print('读取 %s 处源文件，输出xml模型至 %s' % (source_path, uppaal_output))
                uppaal_output = './output.xml'
                report_output = uppaal_output.replace(
                    ".xml", '_report%s.txt' % time.strftime("%Y%m%d%H%M%S", time.gmtime()))
            reader = SolidityFileReader.SolidityFileReader(source_path)
            translator = ContractTranslator.ContractTranslator(reader)
            system = translator.translate()
            UppaalFileGenerator.generate(system, uppaal_output)
            translate_flag = True
        elif not picked_flag:
            property_table = []
            if property_string == '':
                property_string = prompt(
                    'cmd>', bottom_toolbar=bottom_toolbar_2, style=style)
            else:
                if property_string == 'quit':
                    break
                if property_string == 'all':
                    property_string = ""
                    for i in range(1, 27):
                        if args.test_case == "Medical" and i > 11:
                            break
                        property_string += str(i)+','
                    property_string = property_string[:-1]
                property_set = set(eval('[%s]' % property_string))
                title = HTML(
                    'Verifying <style bg="yellow" fg="black">%d properties...</style>' % len(property_set))
                label = HTML('<ansired>verified properties</ansired>: ')
                with ProgressBar(title=title) as pb:
                    web_dict = {}
                    web_dict["result"] = []
                    for i in pb(property_set, label=label):
                        counter_result = ""
                        result = subprocess.run(['%s/uppaal/verifyta' % root_dir, uppaal_output, '%s/properties/property_%d.q' % (
                            root_dir, i), '-t0', '-q', '-u'], capture_output=True)
                        if 'Formula is satisfied.' in result.stdout.decode('utf-8'):
                            result_str = 'true'
                            cpu_time = re.findall(
                                '.*-- CPU user time used : (.*) ms', result.stdout.decode('utf-8'))[0]
                        elif 'Formula is NOT satisfied.' in result.stdout.decode('utf-8'):
                            result_str = 'false'
                            cpu_time = re.findall(
                                '.*-- CPU user time used : (.*) ms', result.stdout.decode('utf-8'))[0]
                            open(report_output, 'a').write('性质 %d 反例:\n' %
                                                           i+result.stderr.decode('utf-8'))
                            counter_str = result.stderr.decode('utf-8')
                            counter_list = counter_str.split('\n')
                            for y in counter_list:
                                if len(y) <= 150:
                                    counter_result += y+'\n'
                        else:
                            result_str = '运行异常'
                            cpu_time = '--'
                            raise Exception(result.stderr)
                        web_dict["result"].append(
                            {"index": i, "result": result_str, "time": cpu_time, "counter_example": counter_result})
                        property_table.append([i, result_str, cpu_time])

                table = tabulate.tabulate(property_table, headers=[
                                          '序号', '验证结果', '耗时(ms)'], tablefmt='grid')
                print('验证完成，反例位于 %s' % report_output)
                print(table)
                with open('../Web/static/%s_res.txt' % args.test_case, 'w') as f:
                    f.write(json.dumps(web_dict))
                picked_flag = True
        else:
            custom_property = prompt(
                'cmd>', bottom_toolbar=bottom_toolbar_3, style=style)
            if custom_property == 'quit':
                break
            open('%s/properties/custom.q' %
                 root_dir, 'w+').write(custom_property)
            result = subprocess.run(['%s/uppaal/verifyta' % root_dir, uppaal_output,
                                    '%s/properties/custom.q' % root_dir, '-t0', '-q', '-u'], capture_output=True)
            if 'Formula is satisfied.' in result.stdout.decode('utf-8'):
                result_str = '满足'
                cpu_time = re.findall(
                    '.*-- CPU user time used : (.*) ms', result.stdout.decode('utf-8'))[0]
            elif 'Formula is NOT satisfied.' in result.stdout.decode('utf-8'):
                result_str = '不满足'
                cpu_time = re.findall(
                    '.*-- CPU user time used : (.*) ms', result.stdout.decode('utf-8'))[0]
                print('性质 %s 反例:\n' % custom_property +
                      result.stderr.decode('utf-8'))
            else:
                result_str = '运行异常'
                cpu_time = '--'
            print('性质 %s 验证完成，验证%s，耗时 %s ms' %
                  (custom_property, result_str, cpu_time))
