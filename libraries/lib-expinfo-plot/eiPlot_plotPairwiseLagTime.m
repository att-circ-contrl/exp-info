function eiPlot_plotPairwiseLagTime( infodata, infofield, ...
  destswanted, srcswanted, trialswanted, ...
  ztype, colmap, colunits, titleprefix, outfilepat )

% function eiPlot_plotPairwiseLagTime( infodata, infofield, ...
%   destswanted, srcswanted, trialswanted, ...
%   ztype, colmap, colunits, titleprefix, outfilepat )
%
% This generates heatmap plots of pairwise shared information vs time and
% lag for all desired channel pairs.
%
% "infodata" is a data structure with pairwise shared information as a
%   function of time and delay, per TIMEWINLAGDATA.txt.
% "infofield" is the fieldname within "infodata" that contains data to be
%   plotted (e.g. 'xcorrconcatdata', 'mutualavgdata', etc).
% "destswanted" is a cell array containing destination channels to consider,
%   or {} to use all destination channels.
% "srcswanted" is a cell array containing source channels to consider, or
%   {} to use all source channels.
% "trialswanted" is a vector containing trial numbers (from "trialnums") to
%   consider, or [] to plot all trials.
% "ztype" is 'symm' or 'asymm', passed as an argument to eiPlot_getZRange().
% "colmap" is the colormap to use for the heatmap.
% "colunits" is the color scale label, or '' to omit the label.
% "titleprefix" is a prefix to use when building plot titles.
% "outfilepat" is a sprintf() pattern to use when generating plot filenames.
%   If only one trial is requested (or if this is single-trial data), this
%   should have two '%s' codes, for source and destination (in that order).
%   If multiple trials are present and requested, this should have three
%   '%s' codes (for source, destination, and trial).
%
% No return value.


% Get plotting-related metadata.

pm = eiPlot_getChanTimeLagMetadata( ...
  infodata, infofield, destswanted, srcswanted, ztype );

many_trials = ( sum(pm.trialmask) > 1 );


%
% Render the plots.

thisfig = figure();
figure(thisfig);

for destidx = 1:pm.destcount
  for srcidx = 1:pm.srccount
    if pm.pairmask(destidx,srcidx)

      for tidx = 1:pm.trialcount
        if pm.trialmask(tidx)

          thisslice = infodata.(infofield)(destidx,srcidx,tidx,:,:);
          thisslice = reshape( thisslice, pm.timecount, pm.delaycount );

          % Remember that we want (y,x) for the plot.
          thisslice = transpose(thisslice);

          % Tolerate gaps in the time series.
          [ thisslice, thistimeseries, thislagseries ] = ...
            nlProc_padHeatmapGaps( ...
              thisslice, pm.timelist_ms, pm.delaylist_ms );


          % Generate this plot.

          clf('reset');

          colormap(thisfig, colmap);

          plottitle = [ titleprefix ' - ' ...
              pm.srctitles{srcidx} ' to ' pm.desttitles{destidx} ];
          if many_trials
            plottitle = [ plottitle ' - ' pm.trialtitles{tidx} ];
          end

          nlPlot_axesPlotSurface2D( gca, thisslice, ...
            thistimeseries, thislagseries, [], [], ...
            'linear', 'linear', 'linear', ...
            'Time (ms)', 'Delay (ms)', plottitle );

          clim(pm.zrange);

          thiscol = colorbar;
          if ~isempty(colunits)
            thiscol.Label.String = colunits;
          end

          fname = 'bogus';
          if many_trials
            fname = sprintf( outfilepat, ...
              pm.srclabels{srcidx}, pm.destlabels{destidx}, ...
              pm.triallabels{tidx} );
          else
            fname = sprintf( outfilepat, ...
              pm.srclabels{srcidx}, pm.destlabels{destidx} );
          end

          saveas( thisfig, fname );

        end
      end

    end
  end
end

close(thisfig);


% Done.
end


%
% This is the end of the file.
