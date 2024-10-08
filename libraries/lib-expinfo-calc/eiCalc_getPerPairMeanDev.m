function [ pairmean pairdev ] = ...
  eiCalc_getPerPairMeanDev( timelagdata, datafield )

% function [ pairmean pairdev ] = ...
%   eiCalc_getPerPairMeanDev( timelagdata, datafield )
%
% This examines time-and-lag analysis data and for each channel pair computes
% the mean and deviation (across time and lag) of the desired analysis output
% field.
%
% "timelagdata" is a data structure per TIMEWINLAGDATA.txt.
% "datafield" is a character vector with the name of the field being operated
%   on (e.g. 'xcorrsingle', 'mutualavg', etc).
%
% "pairmean" is a matrix indexed by (destchan, srcchan) containing the mean
%   of the analysis data field for that channel pair.
% "pairdev" is a matrix indexed by (destchan, srcchan) containing the
%   standard deviation of the analysis data field for that channel pair.



% Get metadata and data.

destchans = timelagdata.destchans;
srcchans = timelagdata.srcchans;

destcount = length(destchans);
srccount = length(srcchans);

thisdata = timelagdata.(datafield);



% Initialize output.

pairmean = zeros([ destcount srccount ]);
pairdev = nan([ destcount srccount ]);



% Consider each pair only once, mask self-comparisions, and avoid squashed.

pairmask = nlUtil_getPairMask( destchans, srcchans );
pairmask = pairmask & eiAux_getPairValidMask( thisdata );



% Calculate statistics.

for destidx = 1:destcount
  for srcidx = 1:srccount
    if pairmask(destidx, srcidx)

      thisslice = thisdata(destidx,srcidx,:,:);
      thisslice = reshape(thisslice, 1, []);
      thisslice = thisslice(~isnan(thisslice));

      if ~isempty(thisslice)
        pairmean(destidx,srcidx) = mean(thisslice);
        pairdev(destidx,srcidx) = std(thisslice);
      end

    end
  end
end


% Done.
end


%
% This is the end of the file.
