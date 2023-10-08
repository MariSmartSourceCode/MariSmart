import os
from solidity_parser import parser
import re

import Classes as Classes
from Classes import default_system


class ContractJsonReader(object):
    def __init__(self, _name_str, _json_source):
        self.json_source = _json_source  # 合约 json 对象
        self.name_str = _name_str  # 合约名，小写
        self.modifier_list = []  # 修饰器 json 列表
        self.function_list = []  # 函数 json 列表
        self.enum_list = []  # 枚举 json 列表
        self.event_list = []  # 事件 json 列表
        for node in self.json_source["subNodes"]:
            if node["type"] == "ModifierDefinition":
                self.modifier_list.append(node)
                continue
            if node["type"] == "FunctionDefinition":
                self.function_list.append(node)
                continue
            if node["type"] == "EventDefinition":
                self.event_list.append(node)
                continue
            if node["type"] == "EnumDefinition":
                self.enum_list.append(node)
        # print([i['name'] for i in self.function_list])


class SolidityFileReader(object):
    def __init__(self, _source_file_path):
        self.source_file_path = _source_file_path  # 合约源文件或目录路径
        self.json_list = []  # 合约源文件解析后的 json 列表
        self.contract_list = []  # 合约 ContractJsonReader 列表
        self.state_variable_list = []  # 全局变量 json 列表

        # 读取合约源文件并解析为 json
        if os.path.isfile(self.source_file_path):
            with open(self.source_file_path, 'r') as f:
                solStr = f.read()
                solStr = self.pretreat(solStr)
                json_source = parser.parse(solStr, loc=True)
                self.obj = parser.objectify(json_source)
                self.json_list.append(json_source)
        else:
            flag = False
            for root, dirs, files in os.walk(self.source_file_path):
                for file in files:
                    if file.endswith('.sol'):
                        flag = True
                        print(os.path.join(root, file))
                        with open(os.path.join(root, file), 'r') as f:
                            solStr = f.read()
                            solStr = self.pretreat(solStr)
                            json_source = parser.parse(solStr, loc=True)
                            self.obj = parser.objectify(json_source)
                            self.json_list.append(json_source)
            if not flag:
                pass
                #raise Exception('no .sol file found in %s' %
                                #self.source_file_path)
        # print(self.json_list)

        # json 分类存入列表
        for json in self.json_list:
            for child in json["children"]:
                if child["type"] == "ContractDefinition":
                    if 'baseContracts' in child.keys() and child['baseContracts'] != []:
                        if 'Shipment' in child["name"] or child['baseContracts'][0]['baseName']['namePath'] == 'Shipment':
                            self.contract_list.append(
                                ContractJsonReader('shipment', child))
                        elif 'Shipper' in child["name"] or child['baseContracts'][0]['baseName']['namePath'] == 'Shipper':
                            self.contract_list.append(
                                ContractJsonReader('shipper', child))
                        elif 'Carrier' in child["name"] or child['baseContracts'][0]['baseName']['namePath'] == 'Carrier':
                            self.contract_list.append(
                                ContractJsonReader('carrier', child))
                        elif 'Consignee' in child["name"] or child['baseContracts'][0]['baseName']['namePath'] == 'Consignee':
                            self.contract_list.append(
                                ContractJsonReader('consignee', child))
                        elif 'PreshipmentInspector' in child["name"] or child['baseContracts'][0]['baseName']['namePath'] == 'PreshipmentInspector':
                            self.contract_list.append(
                                ContractJsonReader('pre_shipment_inspector', child))
                        elif 'ExportPortOperator' in child["name"] or child['baseContracts'][0]['baseName']['namePath'] == 'ExportPortOperator':
                            self.contract_list.append(
                                ContractJsonReader('export_port_operator', child))
                        elif 'ImportPortOperator' in child["name"] or child['baseContracts'][0]['baseName']['namePath'] == 'ImportPortOperator':
                            self.contract_list.append(
                                ContractJsonReader('import_port_operator', child))
                        else:
                            self.contract_list.append(
                                ContractJsonReader(child['name'], child))
                            raise Warning(
                                'unknown contract type: %s' % child["name"])
                    else:
                        self.contract_list.append(
                            ContractJsonReader(child['name'], child))
                        raise Warning(
                            'unknown contract type: %s' % child["name"])
                    continue
        # print([i.name_str for i in self.contract_list])

        # 解析全局变量 json
        for contract in self.json_list:
            children = contract["children"]
            for child in children:
                if child["type"] == "ContractDefinition":
                    sub_nodes = child["subNodes"]
                    for node in sub_nodes:
                        if node["type"] == "StateVariableDeclaration":
                            self.state_variable_list.append(node)
        # print([i['variables'][0]['name'] for i in self.state_variable_list])

    def pretreat(self, solStr) -> str:

        solStr = solStr.replace(
            'shipments[uid_counter] = IShipment(_shipment);', '')
        solStr = solStr.replace(
            'IShipment shipment = new IoTShipment();', '')
        solStr = solStr.replace(
            'shipments[uid_counter] = shipment;', '')
        solStr = solStr.replace(
            'shipments[uid_counter] = IShipment(_shipment);', '')
        solStr = solStr.replace('uint _UID,', '')
        solStr = solStr.replace('IShipment(_shipment).', 'shipment_')
        solStr = solStr.replace("address(this)", "msg_sender")
        solStr = solStr.replace("msg.", "msg_")
        solStr = solStr.replace("block.timestamp", "block_timestamp")
        solStr = solStr.replace("payable", "")
        solStr = solStr.replace("uint", "int")
        solStr = solStr.replace("uint256", "int")
        solStr = solStr.replace("int256", "int")
        solStr = solStr.replace("bytes32", "int")
        solStr = solStr.replace("public", "")
        solStr = solStr.replace(".transfer(", ".send(")
        solStr = solStr.replace('int(uint160', '(')
        solStr = solStr.replace('int(uint160', '(')
        solStr = solStr.replace('{value: escrow_amount}', '')
        solStr = solStr.replace('ether', '')
        solStr = solStr.replace('days', '')
        solStr = solStr.replace('weeks', '*7')
        solStr = solStr.replace('years', '*365')
        solStr = solStr.replace('months', '*30')
        solStr = solStr.replace('shipments[_UID].', 'shipment_')
        solStr = solStr.replace('shipments[UID].', 'shipment_')

        solStr = solStr.replace('shipment.', 'shipment_')

        pattren = re.compile(r'int\s(.+?)\s\= block_timestamp')
        for i in pattren.findall(solStr):
            solStr = solStr.replace(i, 'block_timestamp')
        # print(solStr)
        return solStr


if __name__ == '__main__':
    reader = SolidityFileReader('./verifier/test.sol')
    # reader = SolidityFileReader('./Cases/case_IoT')
