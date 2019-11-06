function busy_period = compute_busy_period_length(flows, n_slots_max)

    n_streams = size(flows,1);
    
    w = n_streams / n_slots_max;
    x(1:n_streams) = w;
    w_next = sum(ceil(x./flows(:,4)')) / n_slots_max;
    
    while w ~= w_next
        w = w_next;
        x(1:n_streams) = w;
        w_next = sum(ceil(x./flows(:,4)')) / n_slots_max;
    end
    
    busy_period = ceil(w_next);
end