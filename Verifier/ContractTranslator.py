import re

from Classes import MaritimeContract, MaritimeFunction, MaritimeSystem, default_system
from SolidityFileReader import SolidityFileReader, ContractJsonReader
import UppaalFileGenerator as UppaalFileGenerator


class ContractTranslator(object):
    def __init__(self, _reader: SolidityFileReader) -> None:
        self.reader = _reader
        self.system = default_system
        self.function = None

    def translate_expression(self, expression_json) -> str:
        if expression_json is not None:
            var_type = expression_json["type"]
            if var_type == "BooleanLiteral":
                if not expression_json["value"]:
                    return "false"
                else:
                    return "true"
            elif var_type == "NumberLiteral":
                return expression_json["number"]
            elif var_type == "Identifier":
                return ' '+expression_json["name"]+' '
            elif var_type == "UnaryOperation":
                operator = expression_json["operator"]
                if expression_json["isPrefix"]:
                    if operator == "++":
                        subExpression = self.translate_expression(
                            expression_json["subExpression"])
                        return subExpression + "=" + subExpression + "+1"
                    elif operator == "--":
                        subExpression = self.translate_expression(
                            expression_json["subExpression"])
                        return subExpression + "=" + subExpression + "-1"
                    else:
                        subExpression = self.translate_expression(
                            expression_json["subExpression"])
                        return operator + subExpression
                else:
                    if operator == "++":
                        subExpression = self.translate_expression(
                            expression_json["subExpression"])
                        return subExpression + "=" + subExpression + "+1"
                    elif operator == "--":
                        subExpression = self.translate_expression(
                            expression_json["subExpression"])
                        return subExpression + "=" + subExpression + "-1"
                    else:
                        subExpression = self.translate_expression(
                            expression_json["subExpression"])
                        return subExpression + operator
            elif var_type == "BinaryOperation":
                left_part = self.translate_expression(expression_json["left"])
                operator = expression_json["operator"]
                right_part = self.translate_expression(
                    expression_json["right"])
                if operator == '=' and 'block_timestamp' in right_part:
                    right_part = right_part.replace('block_timestamp', '0')
                    self.system.clock_set.add(left_part.strip(' ')+'CLK')
                    self.function.timed_reset_list.append(
                        left_part.strip(' ')+'CLK')
                else:
                    return left_part + ' ' + operator+' ' + right_part
            elif var_type == "FunctionCall":
                function_name = self.translate_expression(
                    expression_json["expression"])
                arguments = expression_json["arguments"]
                para_str = ""
                if len(arguments) > 0:
                    for a in arguments:
                        para_str += self.translate_expression(a) + ","
                    para_str = para_str[0:-1]
                if ".transfer" in function_name or ".send" in function_name or ".call.value" in function_name:
                    target_str = function_name.replace(
                        ".transfer", '').replace(".send", '').replace(".call.value", '')
                    return "shipment_externalTransfer(%s,%s)" % (target_str, para_str)
                elif 'require' in function_name:
                    for i in range(len(self.function.require_list)):
                        self.function.require_list[i] += ' && '+para_str
                    return ''
                if function_name.strip(' ').startswith('shipment_get'):
                    # deal with getter function
                    getter_str = function_name.strip(' ')[12:]
                    getter_str = re.sub(r'([A-Z])', r'_\1', getter_str).lower()
                    if para_str == "":
                        getter_str = getter_str.replace(
                            "create_time", "create_timeCLK")
                        getter_str = getter_str.replace(
                            "depart_time", "depart_timeCLK")
                        getter_str = getter_str.replace(
                            "arrive_time", "arrive_timeCLK")
                        getter_str = getter_str.replace(
                            "receive_time", "receive_timeCLK")
                        return getter_str[1:]
                    else:
                        return getter_str[1:] + "[" + para_str + "]"
                else:
                    return function_name + "(" + para_str + ")"
            elif var_type == "MemberAccess":
                var_domain = self.translate_expression(
                    expression_json["expression"])
                var_member = expression_json["memberName"]
                if (var_domain == "msg") and (
                    var_member == "sender" or var_member == "value"
                ):
                    return var_domain + "_" + var_member
                else:
                    return var_domain + "." + var_member
            elif var_type == "IndexAccess":
                var_base = self.translate_expression(expression_json["base"])
                var_index = self.translate_expression(expression_json["index"])
                return var_base + "[" + var_index + "]"
            elif var_type == "StringLiteral":
                return ""
            elif var_type == "TupleExpression":
                if expression_json['components'] != None and len(expression_json['components']) == 1:
                    return self.translate_expression(expression_json['components'][0])
                else:
                    raise ValueError('无法处理长度不为1的TupleExpression,目前长度%d' %
                                     len(expression_json['components']))
            else:
                raise ValueError("can't transfer\n%s" % expression_json)
        else:
            return ""

    def expression_statement(self, s):
        ans = []
        expression = self.translate_expression(s["expression"])
        ans.append(expression)
        return ans

    def if_statement(self, s):
        ans = []

        # deal with condition
        if_condition = self.translate_expression(s["condition"])

        # deal with clock
        if "block_timestamp" in if_condition:
            self.function.timed_condition_list.append(if_condition)
            if_condition = 'TIMED_CONDITION_%d' % self.function.timed_condition_count
            self.function.timed_condition_count += 1
        ans.append('if(%s){' % if_condition)

        # deal with true body part
        if s["TrueBody"] is not None:
            if 'statements' in s["TrueBody"]:
                body_list = self.translate_stmt(
                    s["TrueBody"]["statements"])
                ans += body_list
            else:
                body_list = self.translate_stmt(
                    [s["TrueBody"]])
                ans += body_list
        ans.append('}')

        # deal with false body part
        if s["FalseBody"] is not None:
            if "statements" in s["FalseBody"]:
                body_list = self.translate_stmt(
                    s["FalseBody"]["statements"])
                ans.append('else{')
                ans += body_list
            else:
                body_list = self.translate_stmt(
                    [s["FalseBody"]])
                ans.append('else{')
                ans += body_list
            ans.append('}')

        return ans

    def while_statement(self, s):
        ans = []

        # deal with condition
        while_condition = self.translate_expression(s["condition"])
        ans.append('while(%s){' % while_condition)

        # deal with body
        temp = self.translate_stmt(s["body"]["statements"])
        ans += temp
        ans.append('}')

        return ans

    def for_statement(self, s):
        ans = []
        # deal with condition
        for_condition = self.translate_expression(s["conditionExpression"])

        # deal with loop operation
        loop_expression = self.translate_expression(
            s["loopExpression"]["expression"])
        # deal with init value
        if "initialValue" in s["initExpression"]:
            state_variable = [s["initExpression"]]
            self.variable_list += (
                jv.state_variables_from_json(
                    state_variable, self.get_structure(), self.get_enum()
                )
            )
            init = self.translate_expression(
                s["initExpression"]["initialValue"])
            init_ex = s["initExpression"]["variables"][0]["name"] + "=" + init
        else:
            init_ex = self.translate_expression(
                s["initExpression"]["expression"])
        ans.append('for(%s;%s;%s){' %
                   (init_ex, for_condition, loop_expression))
        # deal with body
        temp = self.translate_stmt(
            s["body"]["statements"])
        ans += temp
        ans.append('}')
        return ans

    def return_statement(self, s):
        ans = []
        expression = self.translate_expression(s)
        ans.append("return %s;" % expression)
        return ans

    def var_declaration_statement(self, s):
        if 'initialValue' in s.keys():
            return ['%s %s = %s;' % (s['variables'][0]["typeName"]["name"], s['variables'][0]["name"], self.translate_expression(s["initialValue"]))]
        else:
            return ['%s %s;' % (s['variables'][0]["typeName"]["name"], s['variables'][0]["name"])]

    def translate_stmt(self, statements) -> list:
        stmtList = []
        for s in statements:
            if "type" not in s:
                raise ValueError(
                    'statement obj expected! but get:\n%s' % str(s))
            else:
                statement_type = s["type"]
                if statement_type == "EmitStatement":
                    pass
                elif statement_type == "ExpressionStatement":
                    temp = self.expression_statement(s)
                    temp[0] += ';'
                    stmtList += temp
                elif statement_type == "IfStatement":
                    temp = self.if_statement(s)
                    stmtList += temp
                elif statement_type == "WhileStatement":
                    temp = self.while_statement(s)
                    stmtList += temp
                elif statement_type == "ForStatement":
                    temp = self.for_statement(s)
                    stmtList += temp
                elif statement_type == "DoWhileStatement":
                    pass
                elif statement_type == "PlaceholderStatement":
                    pass
                elif statement_type == "Continue":
                    pass
                elif statement_type == "Break":
                    pass
                elif statement_type == "Throw":
                    pass
                elif statement_type == "VariableDeclarationStatement":
                    temp = self.var_declaration_statement(s)
                    stmtList += temp
                elif (
                    statement_type == "BooleanLiteral"
                    or "NumberLiteral"
                    or "Identifier"
                ):
                    temp = self.return_statement(s)
                    stmtList += temp
                else:
                    raise (ValueError(
                        'cannot resolve this type:  %s' % str(statement_type)))
        return stmtList

    def translate(self) -> MaritimeSystem:
        self.system = default_system
        # 转换全局变量
        for var_json in self.reader.state_variable_list:
            for var in var_json["variables"]:
                if var.typeName.type == 'Mapping':
                    if [var['typeName']['valueType']['name']+'[]',
                            var['name']] not in self.system.para_list:
                        self.system.para_list.append([var['typeName']['valueType']['name']+'[]',
                                                      var['name']])
                elif var["expression"] != None:
                    if [var["typeName"]["name"],
                            var.name, self.translate_expression(var["expression"])] not in self.system.para_list:
                        self.system.para_list.append([var["typeName"]["name"],
                                                      var.name, self.translate_expression(var["expression"])])
                else:
                    if [var["typeName"]["name"], var["name"]] not in self.system.para_list:
                        self.system.para_list.append(
                            [var["typeName"]["name"], var["name"]])
        # print(self.system.para_list)

        # 转换合约
        for contract_reader in self.reader.contract_list:
            # 找到对应合约的 MaritimeContract 对象
            if contract_reader.name_str == 'shipper':
                contract = self.system.contract_dict['shipper']
            elif contract_reader.name_str == 'carrier':
                contract = self.system.contract_dict['carrier']
            elif contract_reader.name_str == 'consignee':
                contract = self.system.contract_dict['consignee']
            elif contract_reader.name_str == 'pre_shipment_inspector':
                contract = self.system.contract_dict['insepctor']
            elif contract_reader.name_str == 'export_port_operator':
                contract = self.system.contract_dict['exporter']
            elif contract_reader.name_str == 'import_port_operator':
                contract = self.system.contract_dict['importer']
            else:
                continue

            # 转换函数
            for function_json in contract_reader.function_list:
                # 转换函数名，在 contract 中找到对应的 MaritimeFunction 对象
                name_str = function_json['name']
                for function in contract.function_list:
                    if function.name_str == name_str:
                        self.function = function
                        break
                if self.function is None:
                    # raise Warning('unknown function: %s in contract %s' %
                    # (name_str, contract.name_str))
                    continue

                # 转换输入参数
                if function_json['parameters']['parameters'] is not None:
                    for para in function_json['parameters']['parameters']:
                        if 'name' not in para['typeName'].keys():
                            # raise Warning('unknown para type: %s in function %s, contract %s' % (
                            # para['name'], name_str, contract_reader.name_str))
                            continue
                        elif para['typeName']['name'] == 'int':
                            # raise Warning('default range for parameter %s in function %s, contract %s' % (para['name'],
                            # name_str, contract_reader.name_str))
                            self.function.para_list.append(
                                ['int', para['name'], '0', '50'])
                        elif para['typeName']['name'] == 'bool':
                            self.function.para_list.append(
                                ['bool', para['name']])
                        else:
                            self.function.para_list.append(
                                ['int', para['name'], '0', '50'])
                            # raise Warning('unknown para type: %s %s in function %s, contract %s' % (para['typeName']['name'], para['name'],
                            # name_str, contract_reader.name_str))
                            continue

                # 转换函数返回类型
                if function_json['returnParameters'] == []:
                    self.function.return_str = 'void'
                else:
                    self.function.return_str = function_json['returnParameters']['parameters'][0]['typeName']['name']
                # 转换函数体，并维护时间重置和条件信息
                stmt_list = self.translate_stmt(
                    function_json['body']['statements'])
                # 拼接函数体
                para_str = ''
                for para in self.function.para_list:
                    if para_str != '':
                        para_str += ', '
                    para_str += '%s %s' % (para[0], para[1])
                stmt_str = ''
                for stmt in stmt_list:
                    stmt_str += stmt+'\n'
                self.function.stmt_str = '%s %s(%s){\n%s}' % (
                    self.function.return_str, self.function.name_str, para_str, stmt_str)
        return self.system


if __name__ == '__main__':

    reader = SolidityFileReader('a')
    # reader = SolidityFileReader('./Verifier/test.sol')
    # reader = SolidityFileReader('./Cases/case_IoT')
    translator = ContractTranslator(reader)
    translator.translate()
    UppaalFileGenerator.generate(translator.system, './output.xml')
