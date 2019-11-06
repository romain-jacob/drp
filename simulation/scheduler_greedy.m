% Romain Jacob
% April 18, 2016
%
% Compute a greedy schedule, with a fixed round period and based on EDF.
% The resulting schedule is stored and returned.
%
% Original code from Marco Zimmerling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ schedule ] = scheduler_greedy( flows, roundPeriod, param, print )
%GREEDYSCHEDULER Compute a greedy schedule, with a fixed round period and 
% based on EDF. The resulting schedule is stored and returned.

% initialize scheduler state
%   The scheduler assumes starting time of all flows is at t = 0.
    t = 0;
%   Stata : Source | Destination | StartTime | Deadline | Period
    state = flows;  
    
% Mapping with my paramaters name
    
    n_slots_max = param.packet_per_round;
    t_max = 30;
    simu_time = param.horizon;
    
    if print
        fprintf('Schedule:\n');
        fprintf(' #Round | #Slots | Allocation\n');
    end
   
    % determine time until the earliest release time
    time_to_next_release = min(state(:,2)) - t;
    % compute time at the end of the next round
    t_next = t + min(t_max, time_to_next_release + 1);
    while t_next <= simu_time
        % allocate as many released packets as possible according to EDF
        if print
            release_selection = state(:,2) <= t_next - 1;
            A = sortrows(state(release_selection,:),3);
            allocation = zeros(1,min(n_slots_max,size(A,1)));
            for i = 1:min(n_slots_max,size(A,1))
                allocation(i) = A(i,1);
                % update scheduler state: compute next release time and deadline
                % of streams which are allocated a slot in the next round
                state(state(:,1) == A(i,1),2) = state(state(:,1) == A(i,1),2) + streams.periods(A(i,1));
                state(state(:,1) == A(i,1),3) = state(state(:,1) == A(i,1),3) + streams.periods(A(i,1));
            end 
            % update statistics
            n_rounds = n_rounds + 1;
            n_free_slots = n_free_slots + n_slots_max - numel(allocation);
            % print allocation of this round
            fprintf('%5u | %6u | ', (t_next - 1), numel(allocation));
            for i = 1:numel(allocation)
                fprintf('%u ', allocation(i));
            end
            fprintf('\n');
        else
            state = sortrows(state,3);
            release_selection = state(:,2) <= t_next - 1;
            if (sum(release_selection) > 0)
                B = find(release_selection, n_slots_max);
                release_selection(min(end,B(end) + 1):end) = 0;
                state(release_selection,2:3) = state(release_selection,2:3) + [state(release_selection,4) state(release_selection,4)];
            end
            % update statistics
            n_rounds = n_rounds + 1;
            n_free_slots = n_free_slots + n_slots_max - sum(release_selection);
        end

        % advance in time to the end of the next round
        t = t_next;

        % determine time until the earliest release time
        time_to_next_release = max(0, min(state(:,2)) - t);
        % compute time at the end of the next round
        t_next = t + min(t_max, time_to_next_release + 1);
    end  
    
end

