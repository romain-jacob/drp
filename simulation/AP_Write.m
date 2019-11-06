% Romain Jacob
% April 18, 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ node ] = AP_Write( node, flowID, param )
%AP_WRITE Update the state of the appropriate Bolt queue and return the

if (node.BOLT_OUT.next_in == node.BOLT_OUT.next_out) && ...
        node.BOLT_OUT.IND == true
    error('Bolt overflows')
    
else
    node.BOLT_OUT.queue(node.BOLT_OUT.next_in) = flowID ;
    node.BOLT_OUT.IND = true ;
    node.BOLT_OUT.next_in = node.BOLT_OUT.next_in + 1 ;
    if node.BOLT_OUT.next_in > param.S_BOLT_pack
        node.BOLT_OUT.next_in = 1;
    end
    % update the max number of packet in buffer
    current_buffer = node.BOLT_OUT.next_in - node.BOLT_OUT.next_out ;
    if current_buffer < 0
        current_buffer = current_buffer + param.S_BOLT_pack;
    end
    node.BOLT_OUT.max_buffer = max( current_buffer , node.BOLT_OUT.max_buffer );
end
end

