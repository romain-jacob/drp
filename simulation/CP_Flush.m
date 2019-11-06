% Romain Jacob
% April 18, 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ node ] = CP_Flush( node )
%CP_FLUSH Trigger the beginning of a flush operation for the given node.

node.CPFlushCount = node.CPFlushCount + 1;
node.CP_flush_in_progress = true;

end

