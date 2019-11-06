% Romain Jacob
% April 18, 2016
%
% Compute a contiguous schedule, with a fixed round period and based on EDF.
% The resulting schedule is stored and returned.
%
% Based on code from Marco Zimmerling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ schedule ] = scheduler_contiguous( flows, roundPeriod, param, print )
%SCHEDULER_CONTIGUOUS Compute a contiguous schedule, with a fixed round period and 
% based on EDF. The resulting schedule is stored and returned.

% initialize scheduler state
    %   The scheduler assumes starting time of all flows is t = 0.
    t = 0;
    %   Stata : Id | StartTime | Deadline | Period | Source | Destination
    state = flows;  
    %   initialize statistics
    n_rounds = 0;
    n_free_slots = 0;    

% set the output structure
    schedule = zeros(param.packet_per_round + 2, 1);
    
    if print
        fprintf('Schedule:\n');
        fprintf(' #Round | Time | #Slots | Allocation\n');
    end
   
    % Set the beginning epoch of the first round
    t_next = roundPeriod ;
    while t_next <= 2 * param.horizon
        % allocate as many released packets as possible according to EDF
        
        release_selection = state(:,2) <= t_next;
        A = sortrows(state(release_selection,:),3);
        allocation = zeros(1,min(param.packet_per_round,size(A,1)));
        for i = 1:min(param.packet_per_round,size(A,1))
            allocation(i) = A(i,1);
            % update scheduler state: compute next release time and deadline
            % of streams which are allocated a slot in the next round
            state(state(:,1) == A(i,1),2) = state(state(:,1) == A(i,1),2) + state(state(:,1) == A(i,1),4);
            state(state(:,1) == A(i,1),3) = state(state(:,1) == A(i,1),3) + state(state(:,1) == A(i,1),4);
        end  
        % update statistics
        n_rounds = n_rounds + 1;
        n_free_slots = n_free_slots + param.packet_per_round - numel(allocation);
        
        % print allocation of this round
        if print
            fprintf('%5u | %2.2f | %6u | ', n_rounds, t_next, numel(allocation));
            for i = 1:numel(allocation)
                fprintf('%u ', allocation(i));
            end
            fprintf('\n');
        end

        roundSchedule = [n_rounds, t_next, allocation]';
        schedule(1:numel(roundSchedule),n_rounds) = roundSchedule;
            
        % advance in time to the end of the next round
        t = t_next;

        % compute time of the beginning of the next round
        t_next = t + roundPeriod ;
    end  
    
end

