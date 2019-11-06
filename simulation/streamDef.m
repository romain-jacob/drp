% Romain Jacob
% March 9, 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [ stream ] = streamDef( n_s, n_d, l, p, d, D)
%STREAMDEF takes as input the parameters of a stream:
%     - source node ID
%     - destination node ID
%     - load 
%     - stream period
%     - stream deadline
%     - packet deadline
%     and returns the associated structure.

stream = struct(...
    'source'        , n_s, ...
    'destination'   , n_d, ...
    'load'          , l, ...
    'st_period'     , p, ...
    'st_deadline'   , d, ...
    'pack_deadline'  , D);

end

