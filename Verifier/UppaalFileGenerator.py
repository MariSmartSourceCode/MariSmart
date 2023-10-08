from Classes import default_system
from Classes import MaritimeContract, MaritimeFunction, MaritimeSystem


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
    with open('./verifier/uppaal_model.xml', 'r') as f:
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
        # print(new_var_str)
        xml = xml.replace('#INSERT VARIABLE#', new_var_str)

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
                if function.name_str == 'create':
                    function.stmt_str = function.stmt_str.replace(
                        ' shipment_sign ();', 'shipment_create();\n shipment_sign ();')
                function_declaration_str += function.stmt_str+'\n'
            xml = xml.replace('#INSERT %s FUNCTION#' %
                              contract.name_str, edit(function_declaration_str))
            # print(function_declaration_str)
            # 插入 idle 至 called 节点迁移
            transition_str = ''
            for function in contract.function_list:
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
                        update_str += 'msg_sender = %s, %s' % (
                            contract.name_str, call_str)
                        # print(update_str)
                        transition_str += '<transition>\n<source ref="idle"/>\n<target ref="%s"/>\n<label kind="select">%s</label>\n<label kind="guard">%s</label>\n<label kind="assignment">%s</label>\n</transition>' % (
                            function.name_str, select_str, edit(guard_condition_str), edit(update_str))
            xml = xml.replace('#INSERT %s TRANSITION#' %
                              contract.name_str, transition_str)
            with open(output_path, 'w+') as xml_writer:
                xml_writer.write(xml)


if __name__ == '__main__':
    generate(default_system, './output.xml')
