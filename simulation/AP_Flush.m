% Romain Jacob
% April 18, 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ node ] = AP_Flush( node )
%AP_FLUSH Trigger the beginning of a flush operation for the given node.

node.APFlushCount = node.APFlushCount + 1;
node.AP_flush_in_progress = true;

end

