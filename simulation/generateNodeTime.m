% Romain Jacob
% April 18, 2016
%
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ nodeTimeStruct ] = generateNodeTime( node, schedule, nodeData, param )
%GENERATENODETIME Generate the starting time for read and flush operations,
%from both AP and CP for a given node.
%   Because of the protocol design, the operations from CP are synchronised
%   with the round of communication (such that, in the worst-case, a flush
%   terminates just before a round starts. Hence, all nodes share the same
%   time vector for those.
%
%   For AP, it depends on T_flush_receive, so it can change accross the
%   network.

%Define the epochs of the read operations during a flush
ReadRound = 0 : param.C_r_max : (param.S_BOLT_pack - 1)*param.C_r_max;

%Define the epochs of the write operations during after a round
WriteRound = 0 : param.C_w_max : (param.packet_per_round - 1)*param.C_w_max;

%Define CP flush time
CPFlushTime = nodeData(node).T_flush_send  - param.C_f_max ...
                : nodeData(node).T_flush_send ...
                : 2*param.horizon;

%Define CP read time
CPReadTime = zeros(1, param.S_BOLT_pack * numel(CPFlushTime));
for i = 1:numel(CPFlushTime)
    CPReadTime((i-1)*param.S_BOLT_pack + 1 : i*param.S_BOLT_pack) = CPFlushTime(i) + ReadRound;
end

%Define CP write time
CPWriteTime = zeros(1, param.packet_per_round * size(schedule,2));
for i = 1:size(schedule,2)
    CPWriteTime((i-1)*param.packet_per_round + 1 : i*param.packet_per_round) ...
            = schedule(2,i) + param.C_lwb + WriteRound;
end

%Define AP flush time
%   Define offset, at most AP flush period
offset_max  = nodeData(node).T_flush_receive;
offset      = round(offset_max*rand, 3);
APFlushTime = offset ...
               : nodeData(node).T_flush_receive ...
               : 2*param.horizon;

%Define AP read time
APReadTime = zeros(1, param.S_BOLT_pack * numel(APFlushTime));
for i = 1:numel(APFlushTime)
    APReadTime((i-1)*param.S_BOLT_pack + 1 : i*param.S_BOLT_pack) = APFlushTime(i) + ReadRound;
end

%Store all in a structure and output

nodeTimeStruct = struct(...
    'CPFlushTime'   , CPFlushTime , ...
    'CPReadTime'    , CPReadTime  , ...
    'CPWriteTime'   , CPWriteTime , ...
    'APFlushTime'   , APFlushTime , ...    
    'APReadTime'    , APReadTime   ...   
    );
end

