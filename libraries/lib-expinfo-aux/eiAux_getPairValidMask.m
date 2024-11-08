function validmask = eiAux_getPairValidMask( datamatrix, zerothresh )

% function validmask = eiAux_getPairValidMask( datamatrix, zerothresh )
%
% This examines a 5d matrix indexed by (dest, src, trial, win, lag) and
% produces a 3d mask indexed by (dest, src, trial) that's true for entries
% with nonzero finite magnitude and false otherwise.
%
% "datamatrix" is a matrix indexed by (destidx, srcidx, tidx, winidx, lagidx).
%   This is an analysis result "FOOdata" field, per TIMEWINLAGDATA.txt.
% "zerothresh" is the magnitude below which elements are considered to be
%   zero. If omitted, a default value is used.
%
% "validmask" is a matrix indexed by (destidx, srcidx, tidx) that's true for
%   slices of "datamatrix" that have at least one finite nonzero element and
%   false otherwise.


destcount = size(datamatrix,1);
srccount = size(datamatrix,2);
trialcount = size(datamatrix,3);

validmask = false([ destcount srccount trialcount ]);


if ~exist('zerothresh', 'var')
  % Magic value for default "small enough to be zero" threshold.
  zerothresh = 1e-20;
end


for destidx = 1:destcount
  for srcidx = 1:srccount
    for tidx = 1:trialcount

      thisslice = datamatrix(destidx,srcidx,tidx,:,:);
      finitemask = isfinite(thisslice);

      thisvalid = any(finitemask, 'all');

      if thisvalid
        if max( abs(thisslice(finitemask)), [], 'all' ) < zerothresh
          thisvalid = false;
        end
      end

      validmask(destidx,srcidx,tidx) = thisvalid;

    end
  end
end


% Done.
end


%
% This is the end of the file.
