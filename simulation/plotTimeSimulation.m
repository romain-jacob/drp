% Romain Jacob
% October, 2019
%
% Plot script for the time simulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Plot selection
% 1 : plot
% 0 : do not plot
plot_buffers    = 0;
plot_e2elatency = 1;
plot_minlatency = 0;


%% Extract the data for plotting
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% Delays
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
delays            = zeros(3,size(flows,1));
all_delay_ratio   = [] ;
all_flow_data     = [];
headers = { ...
    'flowID', ...
    'src', ...
    'dest', ...
    'period[s]', ...
    'e2e_deadline[s]', ...
    'net_deadline[s]', ...
    'latency_bound[s]', ...
    'seqn', ...
    'send_ts[s]', ...
    'rcv_ts[s]', ...
    'latency[s]', ...
    'slack[s]', ...
    'tightness[%]', ...
    };
fid = fopen('flow_data.csv', 'w' );
for col = 1:length(headers)-1 
    fprintf( fid, '%s,', headers{col} );
end
fprintf( fid, '%s', headers{end} );
fprintf( fid, '\n');
fclose( fid );

for flowID = 1:size(flows,1)
    mean_delay      = mean(flowTime{flowID}(6,:) - flowTime{flowID}(1,:)) ; 
    max_delay       = max(flowTime{flowID}(6,:) - flowTime{flowID}(1,:)) ;
    
    %Extract flow info
    flow        = flows(flowID,1);
    source      = flows(flowID,5);
    dest        = flows(flowID,6);
    period      = flows(flowID,4); 
    e2edeadline = flows(flowID,7); % e2e deadline
    deadline    = flows(flowID,3); % network deadline

    %Compute the analytical bound
    analytic_delay  = C_w_max + C_f_max + C_CP_full ...
                       + period + deadline ...
                       + packet_per_round * C_w_max ...
                       - (packet_per_round - 1) * C_r_max ...
                       + nodeData(dest).T_flush_receive...
                       + C_f_max;

    common = [  flow, source, dest, period, ... 
                e2edeadline, deadline, analytic_delay];
    
    this_flow_delay = flowTime{flowID}(6,:) - flowTime{flowID}(1,:) ;
    this_flow_slack = e2edeadline - this_flow_delay ;
    this_flow_tightness = (this_flow_delay / analytic_delay)*100;
    
    nb_packets = numel(this_flow_delay);
    
    this_flow_data = [  repmat(common, nb_packets, 1), ...
                        (0:nb_packets-1)', ... % seqn
                        flowTime{flowID}(1,:)', ... % send_ts (s)
                        flowTime{flowID}(6,:)', ... % rcv_ts (s)
                        this_flow_delay', ... % latency (s)
                        this_flow_slack', ... % slack (s)
                        this_flow_tightness', ... % tightness (%)
                        ];
    dlmwrite('flow_data.csv', this_flow_data, '-append')
    
    all_delay_ratio = [all_delay_ratio this_flow_tightness];
    
    delays(1,flowID) = mean_delay ; 
    delays(2,flowID) = max_delay ;  
    delays(3,flowID) = analytic_delay ;
end


fprintf('Max delay ratio: %f', max(all_delay_ratio));

%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% Buffer sizes
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
buffers_simu        = zeros(3,N);
buffers_analytic    = zeros(3,N);
for nodeID = 1:N
    buffers_simu(1,nodeID) = nodeData(nodeID).BOLT_IN.max_buffer;
    buffers_simu(2,nodeID) = nodeData(nodeID).BOLT_OUT.max_buffer;
    buffers_simu(3,nodeID) = nodeData(nodeID).CP_MEM.max_buffer;
    
    for flowID = 1:size(flows,1)
        deadline    = flows(flowID,3);
        period      = flows(flowID,4);
        source      = flows(flowID,5);
        dest        = flows(flowID,6);
        
        if nodeID == source
            %BOLT_OUT
            buffers_analytic(2,nodeID) = buffers_analytic(2,nodeID) ...
                                            + ceil((nodeData(nodeID).T_flush_send + C_r_max) / period);
            %CP
            buffers_analytic(3,nodeID) = buffers_analytic(3,nodeID) ...
                                            + 2;
        elseif nodeID == dest
            %CP
            buffers_analytic(3,nodeID) = buffers_analytic(3,nodeID) ...
                                            + 1 ;
            %BOLT_IN
            buffers_analytic(1,nodeID) = buffers_analytic(1,nodeID) ...
                                            + ceil((nodeData(nodeID).T_flush_receive + C_r_max + deadline) / period);
         end
    end
end


RedGreen = [1, 0 ,0 
            0, 1 ,0];
    
close all

%% Buffers
if plot_buffers == 1
    
    figure
    %
    % s(1) = subplot(2,1,1);
    % bar(delays','EdgeColor',[0 0 0]);
    % legend('Mean','Max','Analytical')
    %
    % s(2) = subplot(2,1,2);
    nodes = 1:N;
    weight = 0.3;
    hold on
    bar(nodes(2:N),buffers_analytic(:,2:N)')
    bar(nodes(2:N),buffers_simu(:,2:N)',weight,'FaceColor',[1 1 1])
    legend('BoltIn','BoltOut','CP','Simulation WC')
    hold off
    %
    %
    % figure
    % hold on
    % weight = 0.5;
    % bar(buffers_analytic(:,1)')
    % bar(buffers_simu(:,1)',weight,'FaceColor',[1 1 1])
    % ax = gca;
    % ax.XTickLabels = {'','BoltIn','','BoltOut','','CP',''};
    % legend('Analytical WC','Simulation WC')
    hold off
    
end

%% Plot end-to-end latency ratio
if plot_e2elatency == 1

    figure
    hold on
    max_ratio = max(all_delay_ratio);
    histogram(all_delay_ratio,50,'Normalization','probability')

    Y = get(gca, 'ylim');

    plot([100 100], get(gca, 'ylim'), 'r');
    plot([max_ratio max_ratio], 0.8* get(gca, 'ylim'), 'r:');
    xlabel('End-to-end latency of packets  [ % of analytic bound ]');
    ylabel('Percentage of packets [%]');
    yt = get(gca, 'YTick');
    set(gca,'YTick',yt, 'YTickLabel',yt*100) 
    text(98, 0.95* Y(2), 'Analytic bound',...
        'HorizontalAlignment','right',...
        'VerticalAlignment','top',...
        'Color','red',...
        'FontSize',12)
    text(0.98* max_ratio, 0.8* Y(2), sprintf('%2.0f%%',max_ratio),...
        'HorizontalAlignment','right',...
        'VerticalAlignment','top',...
        'Color','red',...
        'FontSize',12)
    hold off

    ratio_quantile = quantile(all_delay_ratio,[0 0.25 0.50 0.75 1])

end
    
%% Plot of the minimum latency achievable over r

if plot_minlatency == 1
   
    figure
    hold on
    Tfmin = 0.1;
    r = 0.1:0.01:0.99;
    border = 50* ones(size(r));
    % y_source    = (2*(param.C_lwb + param.C_CP_full)+ param.delta_f) ./r ;
    y_source    = (2*param.C_CP_full+ param.delta_f) ./r ;
    y_dest      = ( Tfmin + param.delta_g)./(1 - r) ;
    max_y = max(y_source, y_dest);
    fill( [ r fliplr(r) ] , [border fliplr(max_y)] , 'k');
    alpha(.2);

    plot(r,y_source,'LineWidth', 1.5)
    plot(r,y_dest,'LineWidth', 1.5)

    min_latency = (Tfmin + 2*param.C_CP_full + param.delta_f+ param.delta_g); 
    r_opt = (2*param.C_CP_full + param.delta_f) ...
                    /min_latency;

    legend('Admissible end-to-end deadline','Source constraint','Destination constraint')

    plot([0 r_opt r_opt], [min_latency min_latency 0], 'r-.', 'LineWidth', 1.5);      
    text(0.12, min_latency +2 , num2str(min_latency,'%1.2f s - Smallest admissible end-to-end deadline'),...
        'VerticalAlignment','bottom',...
        'Color','red',...
        'FontSize',12)
    text(r_opt, -2.5, num2str(r_opt,'%1.2f'),...
        'HorizontalAlignment','center',...
        'VerticalAlignment','top',...
        'Color','red',...
        'FontSize',12)
    % plot([0.1 0.99], [limit limit], 'r', 'LineWidth', 1.5);
    axis([0.1 1 0 50]);
    xlabel('Deadline ratio parameter - r [.]');
    ylabel('Admissible end-to-end deadline [s]');
    hold off

end

%% Compute C_net max
C_CP = param.C_CP_full - param.C_lwb ;

D = 10;
U = 3;


r_max = 1 - C_f_max / (U * D);
r = r_max;
C_net_max = 0.5 * ( D - delta_f - delta_g - U ) - C_CP  
r_min = 2*(2*C_net_max + C_CP) / (D- param.delta_const);

D_min = (C_f_max + 2*(2*C_net_max + C_CP)*U)/U + param.delta_const;
%This version fo C_net implies that r = r_max

%% Compute U_max min
D = 10;
C_net = C_net_max;
U_max_min = (C_f_max) / ((1 - r_min)*(D - param.delta_const) );









