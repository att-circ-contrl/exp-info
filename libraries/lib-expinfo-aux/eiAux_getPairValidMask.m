function validmask = eiAux_getPairValidMask( datamatrix, zerothresh )

% function validmask = eiAux_getPairValidMask( datamatrix, zerothresh )
%
% This examines a four-dimensional matrix indexed by (dest, src, win, lag)
% and produces a two-dimensional mask indexed by (dest, src) that's true for
% entries with nonzero finite magnitude and false otherwise.
%
% "datamatrix" is a matrix indexed by (destchan, srcchan, winidix, lagidx).
%   This is an analysis result field, per TIMEWINLAGDATA.txt.
% "zerothresh" is the magnitude below which elements are considered to be
%   zero. If omitted, a default value is used.
%
% "validmask" is a matrix indexed by (destchan, srcchan) that's true for
%   slices of "datamatrix" that have at least one finite nonzero element and
%   false otherwise.


destcount = size(datamatrix,1);
srccount = size(datamatrix,2);

validmask = false([ destcount srccount ]);


if ~exist('zerothresh', 'var')
  % Magic value for default "small enough to be zero" threshold.
  zerothresh = 1e-20;
end


for destidx = 1:destcount
  for srcidx = 1:srccount

    thisslice = datamatrix(destidx,srcidx,:,:);
    finitemask = isfinite(thisslice);

    thisvalid = any(finitemask, 'all');

    if thisvalid
      if max( abs(thisslice(finitemask)), [], 'all' ) < zerothresh
        thisvalid = false;
      end
    end

    validmask(destidx,srcidx) = thisvalid;

  end
end


% Done.
end


%
% This is the end of the file.
