% Romain Jacob
% March 18, 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% April 12 - Script updated for fitting to the RT notations
% 04.05 - Updated according to the paper version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [ result, nodeData ] = acceptanceTestAP( flow, nodeData, param, print)
%ACCEPTANCETESTAP Test of schedulability for the destination AP
%   AP always accepts the new stream if possible. It looks for a valid
%   flush rate, T_flush_receive, such that the policies are satisfied.
%   If a valid T_flush_receive is found, it is stored in nodeData, along with the
%   resulting utilization of Bolt.
%   Overwise, the function returns a failure of the acceptance test.
%
%   The admissibility of the flow set for AP is evaluated besed on
%   T_flush_receive_min, which captures the time triggered used of AP (it
%   needs to flush often enough, up to a maximal frequency, defined by the
%   other tasks to be performed by AP). T_flush_receive_min is a design
%   parameter.

% Compute the constraint on f_receive due to the new stream
T_flush_new = (1-param.r) * flow.pack_deadline - param.delta_g; %Constraint due to the new stream
T_flush_receive_min = param.C_f_max / nodeData(flow.destination).util_AP_max ;

% Compare new to the current value. If new is bigger, keep current.
T_flush_current = nodeData(flow.destination).T_flush_receive;
if T_flush_new < T_flush_current
    T_flush_current = T_flush_new;
    % Verify that f_receive is compatible
    if T_flush_current < T_flush_receive_min
        
        if print
            fprintf('Destination admission: Fail\nDestination AP (node %d) cannot flush fast enough.\n', flow.destination)
        end
        
        result = false;
        return
    end  
end

% Compute the needed buffer size of Bolt
S_BOLT_need = computeBoltStress(T_flush_current, flow, nodeData, param);

% Verify that Bolt does not overflow
if S_BOLT_need <= param.S_BOLT_pack
    %Constraints are satisfied, save T_flush_receive_new and return.
    
    if print
        fprintf('#packets_BOLT_In = %f\n',...
            S_BOLT_need)
        fprintf('Destination admission: OK\nutil_BOLT_In = %f\n\n',...
            S_BOLT_need/param.S_BOLT_pack)
    end
    
    result = true;
    nodeData(flow.destination).T_flush_receive = T_flush_current;
    nodeData(flow.destination).util_BOLT_IN = S_BOLT_need/param.S_BOLT_pack;
    return
else
    %Test if Bolt still overflows when using the minimum flush period
    S_BOLT_need = computeBoltStress(T_flush_receive_min, flow, nodeData, param);
    if S_BOLT_need > param.S_BOLT_pack
        %AP cannot avoid Bolt to overflow. Return a failure.
        
        if print
            fprintf('Overflow of Bolt cannot be avoided.\n')
        end
        
        result = false ;
        return
    else %The new stream will be acceptable. Find the f_current biggest possible.
        %Do a binary search on f_current
        
        if print
            fprintf('f_receive of node %d (needed %2.4f) needs to be reduced to avoid overflow.\n',...
                flow.destination, T_flush_current)
        end
        
        f_max = T_flush_current;
        f_min = T_flush_receive_min;
        f_old = T_flush_current;
        T_flush_current = (f_min+f_max)/2;
        stop_crit = 1e-3;
        while abs(f_old - T_flush_current) > stop_crit
            %Test
            S_BOLT_need = computeBoltStress(T_flush_current, flow, nodeData, param);
            if S_BOLT_need <= param.S_BOLT_pack %test succeeded
                f_min = T_flush_current;
            else
                f_max = T_flush_current;
            end
            f_old = T_flush_current;
            T_flush_current = (f_min+f_max)/2 ;
        end
        %Test final value
        
        if S_BOLT_need > param.S_BOLT_pack %last test failed
            T_flush_current = T_flush_current - stop_crit;
        end
        
        result = true;
        nodeData(flow.destination).T_flush_receive = T_flush_current;
        nodeData(flow.destination).util_BOLT_IN = S_BOLT_need/param.S_BOLT_pack;        
        
        if print
            fprintf('New value for node %d: T_flush_receive = %2.4f\n\n',...
                flow.destination, T_flush_current)
        end
        
    end
end

    
end

%--------------------------------------
function S_BOLT_need = computeBoltStress(T_flush, flow, nodeData, param)
S_BOLT_need = (1 + (T_flush + param.C_r_max)/flow.st_period)*flow.load;

S = size(nodeData(flow.destination).destStream,2);%extract the number of streams having the current node as destination
for k=1:S
    S_BOLT_need = S_BOLT_need + (1 + (T_flush + param.C_r_max)...
                                /nodeData(flow.destination).destStream(k).st_period)...
                                *nodeData(flow.destination).destStream(k).load;
end
S_BOLT_need = ceil(S_BOLT_need);
end