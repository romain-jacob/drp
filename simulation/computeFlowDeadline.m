% Romain Jacob
% March 14, 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Updated according to the notes from 2-7th of April. 
% 04.05 - Updated according to the paper version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ st_deadline ] = computeFlowDeadline( st_period, load, pack_deadline, param)
%COMPUTEFLOWDEADLINE This function takes as imput the (whished)
% flow period, load and e2e_deadline for a flow, the deadline ratio 'r', 
% and the constant delay 'delta_const'. 
% It computes and returns the values of the flow deadline which must be 
% registered for to Blink.

%Compute the flexible deadline (overall deadline minus the fixed delays,
%independant of the protocol)
st_deadline = param.r*pack_deadline - param.delta_f - st_period;
% 
% %Allocate a fraction r of the delay to the LWB and maximize the deadline
% st_deadline = param.r*pack_deadline ...
%                 - st_period;
%The stream deadline must not be bigger than the period
st_deadline = min(st_deadline, st_period);

% The st_deadline must be a multiple of the round time, floor it.
st_deadline = st_deadline - mod(st_deadline, param.C_CP_full);

%The deadline must be bigger than the length of a communication round
%plus the period of the rounds.
%If so, return an error. Latter on it might be relevant to properly 
%function implement this into the request.

if (st_deadline < (param.C_CP_full))
%if (st_deadline - (param.C_lwb)) < 1e-8
    error('That request cannot be fulfilled.\nThe stream deadline would need to be smaller than the length of a LWB round. (%2.2f s)',st_deadline)
end
end

