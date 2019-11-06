% Romain Jacob
% April 14, 2016
%
% This is the main script for the time simulation of the Bolt-embedded
% Wireless Sensor Network. It assumes a given flow set, and evaluate the
% network behavior. At the end, the max deadline and buffer size throughout
% the network.
% 
% The code is making the same assumptions as the analysis from the 2-7th of
% April.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

replay = 0;

%% Initialization
clc 
if replay
    partialReset
else
    clear variables
    timeStep    = 1e-3;     % discrete time step for the simulation     [s]
    horizon     = 120;      % horizon of the simulation                 [s]
    seed        = 2222;     % random seed
    rng(seed);              % fix random number generation
    initialization
    
end
close all

eps = 1e-8;             % precision value for the equality test

debug = 0;

%% Main

roundCount = 0;

%We go further than the horizon to leave enough time for all packets to get
%received
% tic
for t = overall_vector_event
    %% Events from the source of each flow
    for flowID = 1:size(flows,1)
        
        source = flows(flowID,5);
        
        %Look for a write from the source AP
        releaseCount = flowReleaseCount(flowID);
        
        %   The local state of Bolt is updated when the write operation is
        %   completed. This is because CP defines its read based on the
        %   local state of Bolt, and it cannot read out a message before it
        %   is written!!! That is why we consider the time in
        %   flowTime(2,X).
        if releaseCount < size(flowTime{flowID},2) && ...
                abs( t - flowTime{flowID}(2,releaseCount+1) ) < eps
            %Extract the data of interest
            node = nodeData(source);
            %Update the state of the Bolt queue
            node = AP_Write(node, flowID, param);
            %Save the result
            nodeData(source) = node;
            flowReleaseCount(flowID) = releaseCount + 1 ;
        end
    end    
    
    %% Events from the source CP
    for nodeID = 1:N
        %Look for a flush from the source CP
        CPFlushCount = nodeData(nodeID).CPFlushCount;        
        if CPFlushCount < size(nodeTime(nodeID).CPFlushTime,2) && ...
                abs( t - nodeTime(nodeID).CPFlushTime(CPFlushCount+1) ) < eps
            %Extract the data of interest
            node = nodeData(nodeID);
            %Update the state of the Bolt queue
            node = CP_Flush(node);
            %Save the result
            nodeData(nodeID) = node;
        end

        %Look for a read from the source CP
        CPReadCount = nodeData(nodeID).CPReadCount;        
        while CPReadCount < size(nodeTime(nodeID).CPReadTime,2) && ...
                abs( t - nodeTime(nodeID).CPReadTime(CPReadCount+1) ) < eps
            
            %Extract the data of interest
            node = nodeData(nodeID);
            %Update the state of the Bolt queue
            [node, flowTime] = CP_Read(node, flowTime, t, param);
            %Save the result
            nodeData(nodeID) = node;
            CPReadCount = nodeData(nodeID).CPReadCount; 
        end 
    end
     
    %% Event from the network
    % Look for the beginning of a round of communication
    %   Round() also takes care of the epoch at which packets are writen to
    %   the dest Bolt.
    if roundCount < size(schedule,2) && ...
                abs( t - schedule(2,roundCount+1) ) < eps
        roundCount = roundCount + 1;
        current_schedule = schedule(:,roundCount);
        [ flowTime, nodeData ] = Com_Round(current_schedule, t, flowTime, flows, nodeData, param);
    end
    
    %% Events from the destination CP
    for nodeID = 1:N
        %Look for a write from the source CP
        CPWriteCount = nodeData(nodeID).CPWriteCount;        
        while CPWriteCount < size(nodeTime(nodeID).CPWriteTime,2) && ...
                abs( t - nodeTime(nodeID).CPWriteTime(CPWriteCount+1) ) < eps
            %Extract the data of interest
            node = nodeData(nodeID);
            %Update the state of the Bolt queue
            [ node, flowTime] = CP_Write(node, flowTime, t, param);
            %Save the result
            nodeData(nodeID) = node;
            CPWriteCount = nodeData(nodeID).CPWriteCount; 
        end
    end
    
    %% Events from the destination AP
    for nodeID = 1:N
        %Look for a flush from the destination AP
        APFlushCount = nodeData(nodeID).APFlushCount;        
        if APFlushCount < size(nodeTime(nodeID).APFlushTime,2) && ...
                abs( t - nodeTime(nodeID).APFlushTime(APFlushCount+1) ) < eps
            
            
            %Extract the data of interest
            node = nodeData(nodeID);
            %Update the state of the Bolt queue
            node = AP_Flush(node);
            %Save the result
            nodeData(nodeID) = node;
        end

        %Look for a read from the destination AP
        APReadCount = nodeData(nodeID).APReadCount;        
        while APReadCount < size(nodeTime(nodeID).APReadTime,2) && ...
                abs( t - nodeTime(nodeID).APReadTime(APReadCount+1) ) < eps
            
            %Extract the data of interest
            node = nodeData(nodeID);
            %Update the state of the Bolt queue
            [node, flowTime] = AP_Read(node, flowTime, t, param);
            %Save the result
            nodeData(nodeID) = node;
            APReadCount = nodeData(nodeID).APReadCount;         
        end 
    end 
end

% toc
plotTimeSimulation