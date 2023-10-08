from copy import deepcopy as dc


class MaritimeSystem(object):
    def __init__(self, _shipper=None, _carrier=None, _consignee=None, _inspector=None, _exporter=None, _importer=None) -> None:
        self.para_list = []  # 存放全局变量，形如：[int,myvar,0]
        self.clock_set = set()  # 存放时钟变量，形如：myCLK
        self.max_timed_condition = 0  # 最大时钟条件数
        # 存放合约，形如：MaritimeContract
        self.contract_dict = {'shipment': None, 'shipper': _shipper, 'carrier': _carrier,
                              'consignee': _consignee, 'insepctor': _inspector, 'exporter': _exporter, 'importer': _importer}
        for i in self.contract_dict.keys():
            if i == 'shipment':
                continue
            self.max_timed_condition = max(
                self.max_timed_condition, self.contract_dict[i].max_timed_condition)


class MaritimeContract(object):
    def __init__(self, _name_str='', _function_list=[]) -> None:
        self.name_str = _name_str  # 合约类型,小写
        self.function_list = [dc(i) for i in _function_list]  # 合约函数列表
        self.max_timed_condition = 0  # 最大时钟条件数
        for i in self.function_list:
            i.require_list = [j.replace('msg_sender', self.name_str)
                              for j in i.require_list]
            self.max_timed_condition = max(
                self.max_timed_condition, len(i.timed_condition_list))


class MaritimeFunction(object):
    def __init__(self, _name_str='', _require_list=[], _stmt_str='', _para_list=[], _return_str='void', _timed_condition_list=[], timed_reset_list=[]) -> None:
        self.name_str = _name_str
        self.require_list = _require_list  # require语句列表，语句间为 || 关系，语句内部仅允许 && 连接
        # 存放入参，形如：[int,inputpara,lowerbound_str,upperbound_str]
        self.para_list = _para_list
        self.return_str = _return_str  # 函数返回类型
        self.stmt_str = _stmt_str  # 函数字符串
        self.timed_condition_list = _timed_condition_list  # 时钟条件列表
        self.timed_reset_list = timed_reset_list  # 时钟重置列表
        self.timed_condition_count = 0  # 时钟条件数


create = MaritimeFunction('create', ['status==0 && signatures[msg_sender] == false'],
                          'void create(){\nshipment_create();\nshipment_sign();\n}', [], 'void', [], ['create_timeCLK'])

withdraw = MaritimeFunction('withdraw', [
                            'status==status_closed && balances[msg_sender] > 0'], 'void withdraw(){\nshipment_withdraw();\n}')

cancel = MaritimeFunction(
    'cancel', ['status == status_exported'], 'void cancel(){\nshipment_cancel();\n}')

claim_shipper = MaritimeFunction('claim', ['status == status_lost && block_timestamp <= arrive_date + compensation_valid'],
                                 'void\nclaim(int _compensation_amount){\nshipment_claim(_compensation_amount);\n}', [['int', '_compensation_amount', '0', 'compensation_limit']])

close_shipper = MaritimeFunction('close', [
                                 'status==status_created && create_timeCLK > sign_valid'], 'void close(){\nshipment_close();\n}')

shipper = MaritimeContract(
    'shipper', [create, withdraw, cancel, claim_shipper, close_shipper])

sign = MaritimeFunction('sign', ['status==status_created && signatures[msg_sender] == false'],
                        'bool sign(){\nreturn shipment_sign();}', [], 'bool')

close_carrier = MaritimeFunction('close', ['(block_timestamp > arrive_date + compensation_valid && status == status_lost)',
                                 '(receive_timeCLK > compensation_valid && status == status_received)', 'status == status_rearranged'], 'void close(){\nshipment_close();\n}')

depart = MaritimeFunction('depart', ['status == status_exported'],
                          'void depart(){\nshipment_depart();\n}', [], 'void', [], ['depart_timeCLK'])

reportLoss = MaritimeFunction('reportLoss', [
                              'status==status_departed'], 'void reportLoss(){\nshipment_reportLoss();\n}')

reportDamage = MaritimeFunction('reportDamage', [
                                'status==status_departed && is_damaged==false'], 'void reportDamage(){\nshipment_reportDamage();\n}')

arrive = MaritimeFunction('arrive', ['status==status_departed'], 'void arrive(){\nshipment_arrive();\n}', [
], 'void', ['block_timestamp > arrive_date'], ['arrive_timeCLK'])

rearrange = MaritimeFunction('rearrange', [
                             'status==status_imported && arrive_timeCLK > receive_valid'], 'void rearrange(){\nshipment_rearrange();\n}')

compensate = MaritimeFunction('compensate', [
                              'status==status_claimed && compensation_amount >= 0 && balances[carrier] >= compensation_amount'], 'void compensate(){\nshipment_compensate();\n}')

carrier = MaritimeContract('carrier', [
                           sign, withdraw, close_carrier, depart, reportLoss, reportDamage, arrive, rearrange, compensate])

receiveShipment = MaritimeFunction('receiveShipment', ['status==status_imported && arrive_timeCLK<=receive_valid'], 'void receiveShipment(bool _is_damaged){\nshipment_receiveShipment(_is_damaged);\n}', [
                                   ['bool', '_is_damaged', '0', '1']], 'void', [], ['receive_timeCLK'])

claim_consignee = MaritimeFunction('claim', ['status == status_received && (is_delayed || is_damaged) && receive_timeCLK<=compensation_valid'],
                                   'void claim(int _compensation_amount){\nshipment_claim(_compensation_amount);\n}', [['int', '_compensation_amount', '0', 'compensation_limit']])

consignee = MaritimeContract(
    'consignee', [sign, withdraw, receiveShipment, claim_consignee])

inspect = MaritimeFunction('inspect', ['status==status_signed'], 'bool inspect(bool _is_passed){\n if(_is_passed){\nshipment_inspect();\n}else{\nshipment_close();\n}\nreturn _is_passed;\n}', [
                           ['bool', '_is_passed', '0', '1']], 'bool')

pre_shipment_inspector = MaritimeContract(
    'pre_shipment_inspector', [sign, withdraw, inspect])

exportShipment = MaritimeFunction('exportShipment', [
                                  'status==status_inspected'], 'void exportShipment(){\nshipment_exportShipment();\n}')

export_port_operator = MaritimeContract(
    'export_port_operator', [sign, withdraw, exportShipment])

importShipment = MaritimeFunction('importShipment', [
                                  'status==status_arrived'], 'void importShipment(){\nshipment_importShipment();\n}')

import_port_operator = MaritimeContract(
    'import_port_operator', [sign, withdraw, importShipment])

default_system = MaritimeSystem(
    shipper, carrier, consignee, pre_shipment_inspector, export_port_operator, import_port_operator)
