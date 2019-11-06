% Romain Jacob
% April 18, 2016
%
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ timeVector ] = generateFlowTime( flow, mode, param )
%GENERATEFLOWTIME Generate the sequence of actual release time of packets
%for a given flow, i.e., the epochs at which AP starts a write operation
%for the this flow.

%Define initial offset
%   at most (flow period + CP flush period)
offset_max = flow(4) + param.C_CP_full;
offset = round(offset_max*rand, 3);
% offset = 5 * param.C_CP_full ...
%         - param.C_w_max ...
%         - param.C_CP_full ...
%         - param.C_f_max ...
%         + 1e-3 ...
%         ;

t_start     = offset;
t_end       = t_start + param.C_w_min ...
                      + rand * (param.C_w_max - param.C_w_min);
timeVector  = [];

switch lower(mode)
    case 'max'        
        while t_start <= param.horizon
            timeVector = [timeVector [t_start ; t_end]];
            t_start = t_start + flow(4);
            t_end   = t_start + param.C_w_min ...
                              + rand * (param.C_w_max - param.C_w_min);
        end
    case 'rand'
        while t_start <= param.horizon
            timeVector = [timeVector [t_start ; t_end]];
            offset = round(offset_max*rand, 3);
            t_start = t_start + flow(4) + offset;
            t_end   = t_start + param.C_w_min ...
                              + rand * (param.C_w_max - param.C_w_min);
        end
        
    otherwise 
        error('Undefined mode for generation of release time for a flow.')
end
    


end

