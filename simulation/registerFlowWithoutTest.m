% Romain Jacob
% March 18, 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ nodeData ] = registerFlowWithoutTest(  source,  ...
                                            destination, ...
                                            load, ...
                                            st_period, ...
                                            pack_deadline, ...
                                            nodeData, param)
%REGISTERFLOWWITHOUTTEST Direct register of the flow. It is assumed that
%the flow has been identified as admissible by the network.

st_deadline = computeFlowDeadline( st_period, load, pack_deadline, param);
flow = streamDef( source , destination, load , st_period, st_deadline, pack_deadline);

nodeData(source).sourceStream = ...
    [nodeData(source).sourceStream flow];
nodeData(destination).destStream = ...
    [nodeData(destination).destStream flow];

%Necessary to compute T_flush_receive
[~, nodeData] = acceptanceTestAP(flow, nodeData, param, 0);

end

