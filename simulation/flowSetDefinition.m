% Romain Jacob
% April 14, 2016
%
% Define a flow set.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Control flows
% Definition of characteristics for initialization flows
base_l = 1;
base_p = 10;
base_D = 30; 
%Register for the initial registration flows
for node = 2:N
    nodeData = registerFlowWithoutTest(1,node,base_l,base_p,base_D,nodeData,param);
    nodeData = registerFlowWithoutTest(node,1,base_l,base_p,base_D,nodeData,param);
end

%% Data flows
% New flows (high bandwith) from Nodes to Host
load = 1;
period = C_CP_full;
e2edeadline = 10; 
for node = 2:5
    nodeData = registerFlowWithoutTest(node,1,load,period,e2edeadline,nodeData,param);
end

% (unused) Additional flows
% % Register slow data flow from Host to Nodes and from Host to Nodes
% % - Node to Host
% load = 1;
% period = 10;
% latency = 30; 
% for node = 2:N
%     nodeData = registerFlowWithoutTest(node,1,load,period,latency,nodeData,param);
% end
% 
% % - Host to Node
% load = 1;
% period = 10;
% latency = 30;
% for node = 2:N
%     nodeData = registerFlowWithoutTest(1,node,load,period,latency,nodeData,param);    
% end

%% Flows data storage

% Save one flow per row
%  Id | StartTime | Deadline | Period | Source | Destination | e2e Deadline
% A flow with load X is described as X flows of load one.
flows = [];
count = 0;
for node=1:param.N
    S = size(nodeData(node).sourceStream,2); %extract the number of flows having the current node as source
    for k=1:S
        for l = 1:nodeData(node).sourceStream(k).load %extract the load of the current flow
            count = count + 1;
            flows = [flows ; ...
                count ...
                0 ...
                nodeData(node).sourceStream(k).st_deadline ...   % network deadline
                nodeData(node).sourceStream(k).st_period ...
                nodeData(node).sourceStream(k).source ...
                nodeData(node).sourceStream(k).destination ...
                nodeData(node).sourceStream(k).pack_deadline ... % e2e deadline
                ];
        end
    end
end

%%
% Attempt to maximize the stress on the network to show the tighness of the
% bounds (unused)
% 
%     k = 3;
%     period = 0.5 * (k * param.C_CP_full + param.C_lwb);
%     period = ceil(1000*period) / 1000 ;
%     latency = 2 * period / param.r + param.delta_const ;
%     latency = ceil(1000*latency) / 1000 ;
% 
%     % Aiming for the worst-case on the source + network
%     period = round(5 * param.C_CP_full /2,3);
%     deadline = 2*param.C_CP_full + 1e-3;
%     latency = (period+deadline) / param.r + param.delta_const;
% 
%     load = 1;
%     for node = 2:N
%         nodeData = registerFlowWithoutTest(node,1,load,period,latency,nodeData,param);
%     end
%     load = 1;
%     for node = 2:N
%         nodeData = registerFlowWithoutTest(1,node,load,period,latency,nodeData,param);
%     end
% 
%     exp_arrival = 0:period:horizon
%     deadlines = deadline:period:horizon
%     round_start = 0:C_CP_full:horizon
%     round_end = C_lwb:C_CP_full:horizon
% 
%     figure
%     hold on
%     y = [0 2];
%     Y = [0 1];
%     for i = 1:numel(exp_arrival)
%         plot( [exp_arrival(i) exp_arrival(i)],y, 'r')
%     end
%     for i = 1:numel(deadlines)
%         plot( [deadlines(i) deadlines(i)],y, 'r')
%     end
%     for i = 1:numel(round_start)
%         plot( [round_start(i) round_start(i)],Y,'b')
%     end
%     for i = 1:numel(round_end)
%         plot( [round_end(i) round_end(i)],Y,'g')
%     end
%     hold off