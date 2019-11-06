% Romain Jacob
% April 19, 2016
%
% Plot script for the details of delays within a flow
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Extract the data for plotting

%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% Delays
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
delays_simu     = zeros(3,size(flows,1));
delays_analytic = zeros(3,size(flows,1));
for flowID = 1:size(flows,1)
    %delta_source_simu
    delays_simu(1,flowID) = max(flowTime{flowID}(3,:) - flowTime{flowID}(1,:));
    %delta_network_simu
    delays_simu(2,flowID) = max(flowTime{flowID}(4,:) - flowTime{flowID}(3,:));
    %delta_dest_simu
    delays_simu(3,flowID) = max(flowTime{flowID}(6,:) - flowTime{flowID}(4,:));
    
    
%     delays_simu(4,flowID) = max(flowTime{flowID}(4,:) - flowTime{flowID}(3,:));
%     delays_simu(5,flowID) = max(flowTime{flowID}(6,:) - flowTime{flowID}(4,:));
    
    %Compute the analytical delays
    dest        = flows(flowID,6);
    period      = flows(flowID,4);
    deadline    = flows(flowID,3);
    
    delays_analytic(1,flowID) = C_w_max + C_CP_full + S_BOLT_pack * C_r_max; 
    delays_analytic(2,flowID) = period + deadline ; 
    delays_analytic(3,flowID) = packet_per_round * C_w_max ...
                                - (packet_per_round - 1) * C_r_max ...
                                + nodeData(dest).T_flush_receive...
                                + S_BOLT_pack * C_r_max;
                            
%     delays_analytic(4,flowID) = C_w_max + S_BOLT_pack * C_r_max; 
%     delays_analytic(5,flowID) = period + C_lwb ; 
    
end

ratios = delays_simu ./ delays_analytic ;

max_ratios = max(ratios')
min_ratios = min(ratios');
max_delays_analytic = max(delays_analytic');
sum_delays_analytic = sum(delays_analytic);


RedGreen = [1, 0 ,0 
            0, 1 ,0];

% for k = 1:size(flows,1)
%     figure
% 
%     hold on
%     colormap(RedGreen)
%     bar(1:5, ones(5,1),'FaceColor',[0 1 0])
%     bar(1:5, ratios(:,k))
%     hold off
% end













