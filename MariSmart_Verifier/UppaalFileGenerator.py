import os

from Classes import default_system
from Classes import MaritimeContract, MaritimeFunction, MaritimeSystem

HERIZAON_GAP = 400
VERTICAL_GAP = 70


def reverse(stmt) -> str:
    if '<=' in stmt:
        return stmt.replace('<=', '>', 1)
    elif '>=' in stmt:
        return stmt.replace('>=', '<', 1)
    elif '>' in stmt:
        return stmt.replace('>', '<=', 1)
    elif '<' in stmt:
        return stmt.replace('<', '>=', 1)
    else:
        raise ('no legal operator detected in "%s"' % stmt)


def edit(stmt) -> str:
    return stmt.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def generate(system, output_path):
    # 载入 xml 模板
    cur_dir = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(cur_dir, 'uppaal_model.xml'), 'r') as f:
        xml = f.read()

        # 插入新增全局变量
        new_var_str = ''
        for var_tuple in system.para_list:
            if '[' in var_tuple[0]:
                var_tuple[0] = var_tuple[0].strip('[]')
                var_tuple[1] += '[100]'
            if len(var_tuple) == 2:
                new_var_str += '%s %s;\n' % (var_tuple[0], var_tuple[1])
            elif len(var_tuple) == 3:
                new_var_str += '%s %s = %s;\n' % (
                    var_tuple[0], var_tuple[1], str(var_tuple[2]))
        xml = xml.replace('#INSERT VARIABLE#', new_var_str)

        # 插入参与方标识符
        stakeholder_str = ''
        for contract_name in system.contract_dict.keys():
            if contract_name == 'shipment':
                continue
            contract = system.contract_dict[contract_name]
            if len(contract.function_list) == 3:
                stakeholder_str += 'signatures[%s]=true;\n' % contract_name
        xml = xml.replace('#INSERT STAKEHOLDER#', stakeholder_str)

        # 插入新增时钟
        new_clock_str = ''
        for clock_name in system.clock_set:
            new_clock_str += 'clock %s;\n' % clock_name
        # print(new_clock_str)
        xml = xml.replace('#INSERT CLOCK#', new_clock_str)

        # 插入抽象时间条件布尔变量
        timed_condition_str = ''
        for i in range(system.max_timed_condition):
            timed_condition_str += 'bool TIMED_CONDITION_%d;\n' % i
        # print(timed_condition_str)
        xml = xml.replace('#INSERT TIMED CONTIDION BOOL#', timed_condition_str)

        # 生成各合约自动机
        for contract_name in system.contract_dict.keys():
            if contract_name == 'shipment':
                continue
            contract = system.contract_dict[contract_name]

            # 插入函数返回值变量
            return_var_str = ''
            for function in contract.function_list:
                if function.return_str != 'void':
                    return_var_str += '%s %s_ret;\n' % (
                        function.return_str, function.name_str)
            xml = xml.replace('#INSERT %s RET VARIABLE#' %
                              contract.name_str, return_var_str)

            # 插入函数声明
            function_declaration_str = ''
            for function in contract.function_list:
                function_declaration_str += function.stmt_str+'\n'
            xml = xml.replace('#INSERT %s FUNCTION#' %
                              contract.name_str, edit(function_declaration_str))
            # 插入函数调用节点，布局从(HERIZON_GAP, 0)开始向下排列，优先放置激活函数节点
            node_str = ""
            x = HERIZAON_GAP
            y = 0
            for function in contract.function_list:
                # 过滤未激活函数
                if not function.is_activate:
                    continue
                node_str += '<location id="%s" x="%d" y="%d">\n<name>%s</name>\n<committed/>\n</location>\n' % (
                    function.name_str, x, y, function.name_str+'_called')
                y += VERTICAL_GAP
            for function in contract.function_list:
                # 将剩余函数节点放置在激活函数节点下方
                if function.is_activate:
                    continue
                node_str += '<location id="%s" x="%d" y="%d">\n<name>%s</name>\n<committed/>\n</location>\n' % (
                    function.name_str, x, y, function.name_str+'_called')
                y += VERTICAL_GAP
            node_str += '<location id="idle" x="0" y="0">\n<name x="%d" y="%d">idle</name>\n<label kind="invariant" x="%d" y="%d">waitCLK&lt;WAITMAX</label>\n</location>\n' % (
                HERIZAON_GAP*0.05, VERTICAL_GAP*0, HERIZAON_GAP*0.05, VERTICAL_GAP*0.15)
            xml = xml.replace('#INSERT %s NODE#' %
                              contract.name_str, node_str)

            # 插入 idle 至 called 节点迁移
            transition_str = ''
            x = 0
            y = 0
            for function in contract.function_list:
                # 过滤未激活函数
                if not function.is_activate:
                    continue
                # 生成 select 语句
                select_str = ''
                for para in function.para_list:
                    if select_str != '':
                        select_str += ', '
                    if para[0] == 'bool':
                        select_str += '%s:int[0,1] ' % para[1]
                    else:
                        select_str += '%s:int[%s,%s]' % (
                            para[1], str(para[2]), str(para[3]))
                # print(select_str)

                # 生成 guard 语句
                if function.require_list == []:
                    function.require_list = ['true']
                # 对于时间条件的每一组取值，构建一条迁移，迁移中为时间条件、msg_sender赋值，并调用函数
                for require_stmt in function.require_list:
                    for i in range(2**len(function.timed_condition_list)):
                        # 构造时间条件真值表，其中第 j 个时间条件真值为 i & 2**n > 0
                        guard_condition_str = require_stmt
                        # 生成 update 语句
                        update_str = ''
                        call_str = ''
                        para_str = ''
                        for para in function.para_list:
                            if para_str != '':
                                para_str += ','
                            para_str += para[1]
                        if function.return_str == 'void':
                            call_str = '%s(%s)' % (function.name_str, para_str)
                        else:
                            call_str = '%s_ret = %s(%s)' % (
                                function.name_str, function.name_str, para_str)
                        # print(call_str)
                        for j in range(len(function.timed_condition_list)):
                            if i & 2**j > 0:
                                guard_condition_str += '&& %s' % function.timed_condition_list[j]
                                update_str = 'TIMED_CONDITION_%d = true, ' % j
                            else:
                                guard_condition_str += '&& %s' % reverse(
                                    function.timed_condition_list[j])
                                update_str += 'TIMED_CONDITION_%d = false, ' % j
                        for j in function.timed_reset_list:
                            update_str += '%s = 0, ' % j
                        update_str += 'msg_sender = %s, %s' % (
                            contract.name_str, call_str)
                        # print(update_str)
                        transition_str += '<transition>\n<source ref="idle"/>\n<target ref="%s"/>\n' % function.name_str
                        transition_str += '<label kind="select" x="%d" y="%d">%s</label>\n' % (HERIZAON_GAP*0.1, y-VERTICAL_GAP*0.9,
                                                                                               select_str)
                        transition_str += '<label kind="guard" x="%d" y="%d">%s</label>\n' % (
                            HERIZAON_GAP*0.1, y-VERTICAL_GAP*0.6, edit(guard_condition_str))
                        transition_str += '<label kind="assignment" x="%d" y="%d">%s</label>\n' % (
                            HERIZAON_GAP*0.1, y-VERTICAL_GAP*0.3, edit(update_str))
                        transition_str += '<nail x="%d" y="%d"/>\n</transition>' % (
                            0, y)
                y += VERTICAL_GAP

            # 插入 called 至 idle 节点迁移
            x = 0
            y = 0
            for function in contract.function_list:
                # 过滤未激活函数
                if not function.is_activate:
                    continue
                for shipment_call in function.shipment_function_list:
                    # 对于每一种可能的shipment函数调用，构造一条迁移
                    guard_condition_str = 'call_%s' % shipment_call
                    reset_str = 'call_%s=false' % shipment_call
                    transition_str += '<transition>\n<source ref="%s"/>\n<target ref="idle"/>\n' % function.name_str
                    transition_str += '<label kind="synchronisation" x="%d" y="%d">chan_%s!</label>\n' % (
                        HERIZAON_GAP*1.1, y-VERTICAL_GAP*0.9, shipment_call)
                    transition_str += '<label kind="assignment" x="%d" y="%d">waitCLK=0,%s</label>\n' % (
                        HERIZAON_GAP*1.1, y-VERTICAL_GAP*0.6, reset_str)
                    transition_str += '<label kind="guard" x="%d" y="%d">%s</label>\n' % (
                        HERIZAON_GAP*1.1, y-VERTICAL_GAP*0.3, guard_condition_str)
                    transition_str += '<nail x="%d" y="%d"/>\n<nail x="%d" y="%d"/>\n<nail x="%d" y="%d"/>\n</transition>' % (
                        HERIZAON_GAP*1.5, y, HERIZAON_GAP*1.5, -VERTICAL_GAP, 0, -VERTICAL_GAP)
                transition_str += '<transition>\n<source ref="%s"/>\n<target ref="idle"/>\n<label kind="assignment" x="%d" y="%d">waitCLK=0</label>\n<label kind="guard" x="%d" y="%d">no_transition()</label>\n<nail x="%d" y="%d"/>\n<nail x="%d" y="%d"/>\n<nail x="%d" y="%d"/>\n</transition>' % (function.name_str,
                                                                                                                                                                                                                                                                                                       HERIZAON_GAP*1.1, y-VERTICAL_GAP*0.6, HERIZAON_GAP*1.1, y-VERTICAL_GAP*0.3, HERIZAON_GAP*1.5, y, HERIZAON_GAP*1.5, -VERTICAL_GAP, 0, -VERTICAL_GAP)
                y += VERTICAL_GAP

            xml = xml.replace('#INSERT %s TRANSITION#' %
                              contract.name_str, transition_str)
            with open(output_path, 'w+') as xml_writer:
                xml_writer.write(xml)


if __name__ == '__main__':
    generate(default_system, './output.xml')
