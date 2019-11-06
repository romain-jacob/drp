% Romain Jacob
% April 18, 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ node, flowTime] = AP_Read( node, flowTime, current_time, param )
%AP_READ 

node.APReadCount = node.APReadCount + 1;

if node.AP_flush_in_progress
    %Look-up the state of the Bolt queue
    if ~node.BOLT_IN.IND %There is no message to read in queue
        node.AP_flush_in_progress = false;
    else
        %Extract the flowID of the first packet in queue
        flowID = node.BOLT_IN.queue(node.BOLT_IN.next_out);
        %Extract the index of the last packet read out for that flow
        packetID = find(flowTime{flowID}(6,:) ...
            , 1 , 'last');
        %If no packet has been read yet, find return an empty matrix...
        if isempty(packetID)
            packetID = 0;
        end
        
        %If the packet is available, it is served
        if packetID < size(flowTime{flowID},2)  && ...
           flowTime{flowID}(5,packetID+1) ~= 0 && ...
                flowTime{flowID}(5,packetID+1) <= current_time
        
            %Update FlowTime
            flowTime{flowID}(6,packetID + 1) = current_time;
            %Update queue state
            node.BOLT_IN.next_out = node.BOLT_IN.next_out + 1 ;
            if node.BOLT_IN.next_out > param.S_BOLT_pack
                node.BOLT_IN.next_out = 1 ;
            end
            
            if node.BOLT_IN.next_out == node.BOLT_IN.next_in
                node.BOLT_IN.IND = false;
            end
        end
    
    end 

end