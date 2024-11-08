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
%   on (e.g. 'xcorrconcatdata', 'mutualavgdata', etc).
%
% "pairmean" is a matrix indexed by (destchan, srcchan, trial) containing the
%   mean of the analysis data field for that channel pair.
% "pairdev" is a matrix indexed by (destchan, srcchan, trial) containing the
%   standard deviation of the analysis data field for that channel pair.



% Get metadata and data.

destchans = timelagdata.destchans;
srcchans = timelagdata.srcchans;

destcount = length(destchans);
srccount = length(srcchans);

thisdata = timelagdata.(datafield);

trialcount = size(thisdata,3);



% Initialize output.

pairmean = zeros([ destcount srccount trialcount ]);
pairdev = nan([ destcount srccount trialcount ]);



% Consider each pair only once, mask self-comparisions, and avoid squashed.

pairmask = nlUtil_getPairMask( destchans, srcchans );
pairtrialmask = eiAux_getPairValidMask( thisdata );



% Calculate statistics.

for destidx = 1:destcount
  for srcidx = 1:srccount
    for tidx = 1:trialcount
      if pairmask(destidx, srcidx) && pairtrialmask(destidx, srcidx, tidx)

        thisslice = thisdata(destidx,srcidx,tidx,:,:);
        thisslice = reshape(thisslice, 1, []);
        thisslice = thisslice(~isnan(thisslice));

        if ~isempty(thisslice)
          pairmean(destidx,srcidx,tidx) = mean(thisslice);
          pairdev(destidx,srcidx,tidx) = std(thisslice);
        end
      end

    end
  end
end


% Done.
end


%
% This is the end of the file.
