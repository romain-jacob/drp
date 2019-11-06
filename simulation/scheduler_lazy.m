% Romain Jacob
% May 02, 2016
%
% Compute a lazy schedule based on EDF.
% The resulting schedule is stored and returned.
%
% Based on code from Marco Zimmerling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ schedule ] = scheduler_lazy( flows, roundLength, param, print )
%SCHEDULER_LAZY Compute a lazy schedul based on EDF.  
% The resulting schedule is stored and returned.
    
    % Maximal round period
    t_max = 30;

    % compute length of the interval we need to look into the future
    horizon = t_max + compute_busy_period_length(flows, param.packet_per_round);

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
    

    % compute the time at the end of the next round
    state_ = state;
    delta = realmax;
    t_ub = t + horizon;
    n_slots_demanded = 0;
    state_ = sortrows(state_,3);
    t_ = state_(1,3);
    while t_ <= t_ub
        n_slots_demanded = n_slots_demanded + 1;
        state_(1,3) = state_(1,3) + state_(1,4);
        state_ = sortrows(state_,3);
        delta_new = max(( floor((t_ - t) / roundLength) * param.packet_per_round) - n_slots_demanded, 0);
        delta = min(delta_new, delta);
        t_ = state_(1,3);
    end
    t_next = t + min(floor(delta / param.packet_per_round)*roundLength + roundLength, t_max);
    
    while t_next <= 2 * param.horizon
        % allocate as many released packets as possible according to EDF        
        release_selection = state(:,2) <= t_next - roundLength;
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
            fprintf('%5u | %2.2f | %6u | ', n_rounds, t_next - roundLength , numel(allocation));
            for i = 1:numel(allocation)
                fprintf('%u ', allocation(i));
            end
            fprintf('\n');
        end

        %   roundSchedule : round number | StartTime | Allocation
        roundSchedule = [n_rounds, t_next - roundLength, allocation]';
        schedule(1:numel(roundSchedule),n_rounds) = roundSchedule;
            
        % advance in time to the end of the next round
        t = t_next;

        % compute time of the beginning of the next round
        state_ = state;
        delta = realmax;
        t_ub = t + horizon;
        n_slots_demanded = 0;
        state_ = sortrows(state_,3);
        t_ = state_(1,3);
        while t_ <= t_ub
            n_slots_demanded = n_slots_demanded + 1;
            state_(1,3) = state_(1,3) + state_(1,4);
            state_ = sortrows(state_,3);
            delta_new = max(( floor((t_ - t) / roundLength) * param.packet_per_round) - n_slots_demanded, 0);
            delta = min(delta_new, delta);
            t_ = state_(1,3);
        end
        t_next = t + min(floor(delta / param.packet_per_round)*roundLength + roundLength, t_max);
    end  
    
end

