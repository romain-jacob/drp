% Romain Jacob
% April 18, 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ node, flowTime ] = CP_Read( node, flowTime, current_time, param )
%CP_READ 

node.CPReadCount = node.CPReadCount + 1;

if node.CP_flush_in_progress
    %Look-up the state of the Bolt queue
    if ~node.BOLT_OUT.IND %There is no message to read in queue
        node.CP_flush_in_progress = false;
    else
        %Extract the flowID of the first packet in queue
        flowID = node.BOLT_OUT.queue(node.BOLT_OUT.next_out);
        %Extract the index of the last packet read out
        packetID = find(flowTime{flowID}(3,:) ...
            , 1 , 'last');
        %If no packet has been read yet, find return an empty matrix...
        if isempty(packetID)
            packetID = 0;
        end
        
        %If the packet is available, it is served
        if packetID < size(flowTime{flowID},2)  && ...
           flowTime{flowID}(2,packetID+1) ~= 0 && ...
                flowTime{flowID}(2,packetID+1) <= current_time
            
            % Update the various structures
            %   Update FlowTime
            flowTime{flowID}(3,packetID + 1) = current_time;

            %   Update BOLT queue state
            node.BOLT_OUT.next_out = node.BOLT_OUT.next_out + 1 ;
            if node.BOLT_OUT.next_in >  param.S_BOLT_pack
                node.BOLT_OUT.next_in = 1 ;
            end
            if node.BOLT_OUT.next_out == node.BOLT_OUT.next_in
                node.BOLT_OUT.IND = false;
            end

            %   Update CP memory state
            node.CP_MEM.counter_out = node.CP_MEM.counter_out + 1 ;
            % update the max number of packet in buffer
            node.CP_MEM.current_buffer = node.CP_MEM.current_buffer + 1 ;
            node.CP_MEM.max_buffer = max( node.CP_MEM.max_buffer , node.CP_MEM.current_buffer ) ;    
        end 
    end

end

