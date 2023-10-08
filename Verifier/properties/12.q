Shipment.lost --> Shipment.claimed && block_timestamp <= arrive_date + compensation_valid || Shipment.closed && block_timestamp > arrive_date + compensation_valid
