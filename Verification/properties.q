// Functional Correctness
A[] (sum(i:int[1,6])balances[i]) >=0
A[] (sum(i:int[0,6])net[i]) ==0
A[] (sum(i:int[1,6])balances[i]) == net[0]
Shipment.closed --> (forall(i:int[1,6])balances[i]==0)
Shipment.departed --> Shipment.lost || Shipment.arrived
A<> Shipment.closed

// Time-related Correctness
A[] is_delayed imply block_timestamp > arrive_date
Carrier.arrive_called && block_timestamp>arrive_date -->is_delayed
Shipment.lost --> Shipment.claimed && block_timestamp <= arrive_date + compensation_valid || Shipment.closed && block_timestamp > arrive_date + compensation_valid
Shipment.arrived --> Shipment.received && arrive_timeCLK <= receive_valid || Shipment.rearranged && arrive_timeCLK > receive_valid

// Legality
A[] compensation_limit < 835 or compensation_limit < 2.5 * weight
A[]is_lost imply (net[carrier]+balances[carrier]>=-835 or net[carrier]+balances[carrier]>=-weight*2.5)
A[] is_damaged imply (net[carrier]+balances[carrier]>=transportation_fee-875 or net[carrier]+balances[carrier]>=transportation_fee-weight*2.5)
A[] (is_delayed imply net[carrier]+balances[carrier]>=transportation_fee*(1-2.5))
A[] compensation_limit < 666.67 or compensation_limit < 2 * weight
A[]is_lost imply (net[carrier]+balances[carrier]>=-666.67 or net[carrier]+balances[carrier]>=-weight*2)
A[] is_damaged imply (net[carrier]+balances[carrier]>=transportation_fee-666.67 or net[carrier]+balances[carrier]>=transportation_fee-weight*2)
A[] (is_delayed imply net[carrier]+balances[carrier]>=transportation_fee*(1-2))
A[] ((is_damaged && Consignee.claim_called) imply receive_timeCLK<=60)
A[] Carrier.rearrange_called imply arrive_timeCLK>60