function validmask = ...
  eiAux_getDesiredPairMask( infodata, destswanted, srcswanted )

% function validmask = ...
%   eiAux_getDesiredPairMask( infodata, destswanted, srcswanted )
%
% This generates a mask indexed by (dest, src) that's true for pairs that
% have sources and destinations in the desired lists and false otherwise.
%
% "infodata" is a data structure with pairwise shared information as a
%   function of time and delay, per TIMEWINLAGDATA.txt.
% "destswanted" is a cell array with the names of desired destination
%   channels, or {} to accept all channels.
% "srcswanted" is a cell array with the names of desired source channels,
%   or {} to accept all channels.
%
% "validmask" is a matrix indexed by (destidx,srcidx) that's true if both
%   the source and destination are desired and false otherwise. Sources and
%   destinations used for indexing are those in "infodata".


% Get metadata.

destchans = infodata.destchans;
srcchans = infodata.srcchans;

destcount = length(destchans);
srccount = length(srcchans);



% Initialize output.

validmask = true([ destcount srccount ]);



% Get validity masks and  apply them.

destsvalid = true(size(destchans));
if ~isempty(destswanted)
  destsvalid = contains(destchans, destswanted);
end
validmask(~destsvalid,:) = false;

srcsvalid = true(size(srcchans));
if ~isempty(srcswanted)
  srcsvalid = contains(srcchans, srcswanted);
end
validmask(:,~srcsvalid) = false;



% Done.
end


%
% This is the end of the file.
