A[] (!Shipper.idle || !Carrier.idle || !Consignee.idle || !PreShipmentInspector.idle || !ExportPortOperator.idle || !ImportPortOperator.idle ) imply already_create
A[] (!Shipper.idle && !Shipper.create_called || !Carrier.idle && !Carrier.sign_called || !Consignee.idle && !Consignee.sign_called || !PreShipmentInspector.idle && !PreShipmentInspector.sign_called || !ExportPortOperator.idle && !ExportPortOperator.sign_called || !ImportPortOperator.idle && !ImportPortOperator.sign_called ) imply already_sign
A[] (Shipper.create_called || Shipper.cancel_called || Shipper.close_called || Carrier.sign_called || Consignee.sign_called || PreShipmentInspector.sign_called || PreShipmentInspector.inspect_called || ExportPortOperator.sign_called || ExportPortOperator.exportShipment_called) imply !already_depart
Shipment.departed --> Shipment.lost || Shipment.arrived
A[] (Shipper.claim_called || Carrier.rearrange_called || Consignee.receiveShipment_called || ImportPortOperator.importShipment_called) imply already_arrive
A<> Shipment.closed
A[] (sum(i:int[1,6])balances[i]) >=0
A[] (sum(i:int[0,6])net[i]) ==0
A[] (sum(i:int[1,6])balances[i]) == net[0]
Shipment.closed --> (forall(i:int[1,6])balances[i]==0)
A[] (is_delayed imply block_timestamp > arrive_date) && (block_timestamp > arrive_date && Shipment.arrived imply is_delayed)
is_delayed --> Shipment.claimed || Shipment.closed && arrive_timeCLK>compensation_valid
A[] (is_lost imply already_reportLoss) && (already_reportLoss imply is_lost)
is_lost --> Shipment.claimed || Shipment.closed && block_timestamp>arrive_date+compensation_valid
A[] (is_damaged imply already_reportDamage) && (already_reportDamage imply is_damaged)
is_damaged --> Shipment.claimed || Shipment.closed && arrive_timeCLK>compensation_valid
A[] compensation limit <835 and compensation limit <2.5*weight 
A[] is_delayed && !is_damaged && !is_lost imply net[carrier]+balances[carrier]>=transportation_fee*(1-2.5)
A[] (is_damaged || is_lost) imply (net[carrier]+balances[carrier]>= transportation_fee-835 && net[carrier]+balances[carrier]>= transportation_fee-weight*2.5)
A[] Consignee.claim_called imply receive_timeCLK<=60
A[] Carrier.rearrange_called imply arrive_timeCLK>90
A[] compensation limit <666.67 and compensation limit <2*weight 
A[] is_delayed && !is_damaged && !is_lost imply net[carrier]+balances[carrier]>=transportation_fee*(1-1)
A[] (is_damaged || is_lost) imply (net[carrier]+balances[carrier]>= transportation_fee-666.67 && net[carrier]+balances[carrier]>= transportation_fee-weight*2)
A[] Consignee.claim_called imply receive_timeCLK<=21
A[] Carrier.rearrange_called imply arrive_timeCLK>60