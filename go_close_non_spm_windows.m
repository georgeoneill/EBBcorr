function close_non_spm_windows()
%==========================================================================
hMenu = spm_figure('FindWin','Menu');
hInt  = spm_figure('FindWin','Interactive');
hGra  = spm_figure('FindWin','Graphics');
hSat  = spm_figure('FindWin','Satellite');
hBat  = spm_figure('FindWin','cfg_ui');

h     = setdiff(findobj(get(0,'children'),'flat','visible','on'), ...
    [hMenu; hInt; hGra; hSat; hBat]);
close(h,'force');