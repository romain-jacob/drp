% Romain Jacob
% April 18, 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ flowTime, nodeData ] = Com_Round( current_schedule, current_time, flowTime, flows, nodeData, param )
%COM_ROUND 

for slot = 1 : param.packet_per_round
    
    %Identify the flow which is allocated a slot
    flowID = current_schedule(slot+2);
    
    %Check for end of allocation
    if flowID == 0
        break
    end
    
    %Find the first non-served packet
    packetID = find(flowTime{flowID}(4,:) ...
            , 1 , 'last');
    %If no packet has been read yet, find return an empty matrix...
    if isempty(packetID)
        packetID = 0;
    end
    
    %If the packet is available, it is served
    if packetID < size(flowTime{flowID},2)  && ...
       flowTime{flowID}(3,packetID+1) ~= 0 && ...
            flowTime{flowID}(3,packetID+1) <= current_time
        
        %Update the flowTime matrix
        flowTime{flowID}(4,packetID+1) = current_time + param.C_lwb;
                                    
        %Update source CP memory state
        nodeID = flows(flowID,5); %Source node of the current flow
        node = nodeData(nodeID);
        node.CP_MEM.counter_out = node.CP_MEM.counter_out - 1;
        node.CP_MEM.current_buffer  = node.CP_MEM.current_buffer - 1 ;
        nodeData(nodeID) = node;
        
        %Update the destination CP memory state
        nodeID = flows(flowID,6); %Destination node of the current flow
        node = nodeData(nodeID);
        node.CP_MEM.queue_in(node.CP_MEM.next_in) = flowID ;
        node.CP_MEM.IND = true ;
        node.CP_MEM.next_in = node.CP_MEM.next_in + 1 ;
        if node.CP_MEM.next_in > param.packet_per_round
            node.CP_MEM.next_in = 1;
        end
        %   update the max number of packet in buffer
        node.CP_MEM.current_buffer = node.CP_MEM.current_buffer + 1 ;
        node.CP_MEM.max_buffer = max( node.CP_MEM.max_buffer , node.CP_MEM.current_buffer ) ;
        nodeData(nodeID) = node;
    end
end

