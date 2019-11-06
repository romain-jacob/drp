% Romain Jacob
% April 18, 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ node, flowTime] = CP_Write( node, flowTime, current_time, param )
%CP_WRITE
%   This is the function called after a round of communication. CP writes
%   packets to Bolt is the same order it received them from the network.

node.CPWriteCount = node.CPWriteCount + 1;

%Look-up the state of the CP queue
if node.CP_MEM.IND %There is at least one message in queue to be written to Bolt 
    
    %Extract the flowID of the first packet in queue
    flowID = node.CP_MEM.queue_in(node.CP_MEM.next_out);

    %Extract the index of the last packet written to Bolt
    packetID = find(flowTime{flowID}(5,:) ...
        , 1 , 'last');
    %If no packet has been read yet, find return an empty matrix...
    if isempty(packetID)
        packetID = 0;
    end

    %If the packet is available, it is served
    if packetID < size(flowTime{flowID},2)  && ...
       flowTime{flowID}(4,packetID+1) ~= 0 && ...
            flowTime{flowID}(4,packetID+1) <= current_time
    
        % Update the various structures
        %   Update FlowTime
        flowTime{flowID}(5,packetID+1) = current_time + param.C_w_max;

        %   Update CP memory state
        node.CP_MEM.next_out = node.CP_MEM.next_out + 1 ;
        if node.CP_MEM.next_out > param.packet_per_round
            node.CP_MEM.next_out = 1 ;
        end
        if node.CP_MEM.next_out == node.CP_MEM.next_in
            node.CP_MEM.IND = false;
        end
        node.CP_MEM.current_buffer = node.CP_MEM.current_buffer - 1 ;

        %   Update BOLT queue state
        if (node.BOLT_IN.next_in == node.BOLT_IN.next_out) && ...
                node.BOLT_IN.IND == true
            error('Bolt overflows')
        else
            node.BOLT_IN.queue(node.BOLT_IN.next_in) = flowID ;
            node.BOLT_IN.IND = true ;
            node.BOLT_IN.next_in = node.BOLT_IN.next_in + 1 ;
            if node.BOLT_IN.next_in > param.S_BOLT_pack
                node.BOLT_IN.next_in = 1 ;
            end
            % update the max number of packet in buffer
            current_buffer = node.BOLT_IN.next_in - node.BOLT_IN.next_out ;
            if current_buffer < 0
                current_buffer = current_buffer + param.S_BOLT_pack;
            end
            node.BOLT_IN.max_buffer = max( current_buffer , node.BOLT_IN.max_buffer );
        end
    end
end
    

end

