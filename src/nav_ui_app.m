function app = nav_ui_app(projectRoot)
%NAV_UI_APP  Intelligent Navigation UI - ISE 333 Course Project.
%
%   Implements ALL basic requirements (BR-1 .. BR-11) and ALL five
%   optional requirements (OR-1 .. OR-5) in a single unified interface.

% =====================================================================
%  1.  LOAD MAP & BUILD ROAD MASK
% =====================================================================
    mapPath  = fullfile(projectRoot, 'MapForUI.jpg');
    if exist(mapPath, 'file') ~= 2, error('Map not found: %s', mapPath); end
    mapImage = imread(mapPath);
    [mapH, mapW, ~] = size(mapImage);
    roadMask = build_road_mask(mapImage);

% =====================================================================
%  2.  STYLE CONSTANTS
% =====================================================================
    BD = [0.18 0.20 0.25];  BP = [0.22 0.24 0.30];
    BB = [0.35 0.38 0.48];  BA = [0.25 0.55 0.85];
    FL = [0.85 0.88 0.95];  FO = [0.55 0.85 0.60];
    FS = [0.60 0.63 0.75];  FN = 'Segoe UI';

% =====================================================================
%  3.  FIGURE
% =====================================================================
    ss = get(0,'ScreenSize');
    fw = min(1400, ss(3)*0.88); fh = min(900, ss(4)*0.88);
    fig = figure('Name','Intelligent Navigation UI', ...
        'NumberTitle','off','Color',BD,'MenuBar','none','ToolBar','none', ...
        'Position',[(ss(3)-fw)/2 (ss(4)-fh)/2 fw fh],'Resize','on', ...
        'CloseRequestFcn',@(src,~)delete(src));

% =====================================================================
%  4.  MAP AXES  (left 69 %)  +  RIGHT-CLICK CONTEXT MENU (P9)
% =====================================================================
    mp = uipanel('Parent',fig,'Units','normalized', ...
        'Position',[0.005 0.06 0.685 0.935],'BackgroundColor',BD,'BorderType','none');
    mapAx = axes('Parent',mp,'Units','normalized', ...
        'Position',[0.01 0.01 0.98 0.98],'Color',[0 0 0]);
    hImg = imshow(mapImage,'Parent',mapAx);

    % ---- Right-click context menu (P9) ----
    cmenu = uicontextmenu('Parent',fig);
    uimenu(cmenu,'Label','Add IV here',        'Callback',@(~,~)onAddIV(fig));
    uimenu(cmenu,'Label','Auto-Add IV here',   'Callback',@(~,~)onAutoAddIV(fig));
    uimenu(cmenu,'Label','Measure Distance',   'Callback',@(~,~)onDistBtn(fig));
    uimenu(cmenu,'Label','Measure Trajectory',  'Callback',@(~,~)onTrajBtn(fig));
    uimenu(cmenu,'Label','Generate Street View','Callback',@(~,~)onStreetViewBtn(fig));
    uimenu(cmenu,'Label','Find Path',           'Callback',@(~,~)onPathBtn(fig));
    set(mapAx,'UIContextMenu',cmenu);
    set(hImg,'UIContextMenu',cmenu);

% =====================================================================
%  5.  RIGHT PANEL  (right 30 %)
% =====================================================================
    rp = uipanel('Parent',fig,'Units','normalized', ...
        'Position',[0.695 0.06 0.30 0.935],'BackgroundColor',BP,'BorderType','none');

    % ---- Mode indicator ----
    modeL = uicontrol('Parent',rp,'Style','text','Units','normalized', ...
        'Position',[0.03 0.97 0.94 0.025],'String','Mode: Idle', ...
        'FontName',FN,'FontSize',11,'FontWeight','bold', ...
        'BackgroundColor',BP,'ForegroundColor',FO,'HorizontalAlignment','center');

    % ---- Coordinate display (P6: more prominent position) ----
    coordDisp = uicontrol('Parent',rp,'Style','text','Units','normalized', ...
        'Position',[0.03 0.945 0.94 0.023],'String','Coords: --', ...
        'FontName',FN,'FontSize',10,'FontWeight','bold', ...
        'BackgroundColor',[.16 .18 .24],'ForegroundColor',[.3 1 .5],'HorizontalAlignment','center');

    % ========== VEHICLE CONTROLS ==========
    sep(rp,0.96,BB); stit(rp,0.94,'VEHICLE CONTROLS',FN,BP,FS);

    lab(rp,[0.03 0.915 0.28 0.022],'Heading(deg):',FN,BP,FL);
    angIn = uicontrol('Parent',rp,'Style','edit','Units','normalized', ...
        'Position',[0.32 0.915 0.14 0.022],'String','0','FontName',FN,'FontSize',9, ...
        'BackgroundColor',[.95 .95 .97]);
    lab(rp,[0.50 0.915 0.18 0.022],'Scale:',FN,BP,FL);
    scIn = uicontrol('Parent',rp,'Style','edit','Units','normalized', ...
        'Position',[0.68 0.915 0.14 0.022],'String','1','FontName',FN,'FontSize',9, ...
        'BackgroundColor',[.95 .95 .97]);

    btn(rp,[0.03 0.885 0.30 0.028],'➕ Add IV',FN,BA,[1 1 1],@(~,~)onAddIV(fig));
    btn(rp,[0.35 0.885 0.30 0.028],'❌ Remove',FN,[.7 .3 .3],[1 1 1],@(~,~)onRemoveIV(fig));
    btn(rp,[0.67 0.885 0.30 0.028],'📋 Report',FN,BB,[1 1 1],@(~,~)onReportIV(fig));

    lab(rp,[0.03 0.86 0.94 0.02],'Loaded IVs:',FN,BP,FL);
    ivLB = uicontrol('Parent',rp,'Style','listbox','Units','normalized', ...
        'Position',[0.03 0.77 0.94 0.088],'String',{'(none)'},'Value',1, ...
        'FontName',FN,'FontSize',9, ...
        'BackgroundColor',[.28 .30 .36],'ForegroundColor',[.9 .9 .95], ...
        'Callback',@(~,~)onListboxSelect(fig));

    % ========== MEASUREMENT ==========
    sep(rp,0.76,BB); stit(rp,0.74,'MEASUREMENT',FN,BP,FS);
    btn(rp,[0.03 0.71 0.30 0.028],'📏 Distance',FN,BB,[1 1 1],@(~,~)onDistBtn(fig));
    btn(rp,[0.35 0.71 0.30 0.028],'🛣️ Traj',FN,BB,[1 1 1],@(~,~)onTrajBtn(fig));
    btn(rp,[0.67 0.71 0.30 0.028],'🗑️ Clear',FN,BB,[1 1 1],@(~,~)onClearMeas(fig));
    dR = uicontrol('Parent',rp,'Style','text','Units','normalized', ...
        'Position',[0.03 0.685 0.45 0.022],'String','Dist: --', ...
        'FontName',FN,'FontSize',9,'BackgroundColor',BP,'ForegroundColor',FL, ...
        'HorizontalAlignment','left');
    tR = uicontrol('Parent',rp,'Style','text','Units','normalized', ...
        'Position',[0.50 0.685 0.47 0.022],'String','Traj: --', ...
        'FontName',FN,'FontSize',9,'BackgroundColor',BP,'ForegroundColor',FL, ...
        'HorizontalAlignment','left');

    % ========== MAP ROTATION ==========
    sep(rp,0.675,BB); stit(rp,0.655,'MAP ROTATION',FN,BP,FS);
    lab(rp,[0.03 0.63 0.25 0.022],'Angle(deg):',FN,BP,FL);
    rotIn = uicontrol('Parent',rp,'Style','edit','Units','normalized', ...
        'Position',[0.29 0.63 0.16 0.022],'String','0','FontName',FN,'FontSize',9, ...
        'BackgroundColor',[.95 .95 .97]);
    btn(rp,[0.48 0.625 0.49 0.028],'🔄 Rotate Map',FN,BB,[1 1 1],@(~,~)onRotate(fig));

    % ========== OR TABS ==========
    sep(rp,0.61,BB);
    stit(rp,0.59,'OPTIONAL FEATURES',FN,BP,FS);

    tg = uitabgroup('Parent',rp,'Units','normalized','Position',[0.02 0.01 0.96 0.575]);

    % ---- OR-1  Skeleton ----
    t1 = uitab(tg,'Title','OR1:Skeleton','BackgroundColor',BP);
    btn(t1,[0.03 0.90 0.30 0.07],'⛏️ Extract',FN,BA,[1 1 1],@(~,~)onSkelExtract(fig));
    btn(t1,[0.35 0.90 0.30 0.07],'✅ End',FN,BB,[1 1 1],@(~,~)onSkelEnd(fig));
    btn(t1,[0.67 0.90 0.30 0.07],'🗑️ Clear',FN,[.6 .3 .3],[1 1 1],@(~,~)onSkelClear(fig));
    btn(t1,[0.03 0.82 0.46 0.07],'🦴 Show Skel',FN,BB,[1 1 1],@(~,~)onSkelShow(fig));
    btn(t1,[0.51 0.82 0.46 0.07],'🗺️ Road Area',FN,BB,[1 1 1],@(~,~)onSkelRoadArea(fig));
    skelInfo = uicontrol('Parent',t1,'Style','text','Units','normalized', ...
        'Position',[0.03 0.75 0.94 0.05],'String','Points: 0', ...
        'FontName',FN,'FontSize',9,'BackgroundColor',BP,'ForegroundColor',FL, ...
        'HorizontalAlignment','left');
    skelAx = axes('Parent',t1,'Units','normalized','Position',[0.05 0.02 0.90 0.70], ...
        'Color',[.1 .1 .14],'XTick',[],'YTick',[]); axis(skelAx,'off');

    % ---- OR-2  Local View ----
    t2 = uitab(tg,'Title','OR2:LocalView','BackgroundColor',BP);
    lab(t2,[0.03 0.92 0.28 0.06],'Range (m):',FN,BP,FL);
    rgIn = uicontrol('Parent',t2,'Style','edit','Units','normalized', ...
        'Position',[0.32 0.92 0.18 0.06],'String','100','FontName',FN,'FontSize',9, ...
        'BackgroundColor',[.95 .95 .97]);
    btn(t2,[0.53 0.92 0.20 0.06],'Update',FN,BB,[1 1 1],@(~,~)updateLocalView(fig));
    dirBtn = btn(t2,[0.75 0.92 0.22 0.06],'Show Direction',FN,BB,[1 1 1],@(~,~)onToggleLocalDirection(fig));
    localInfo = uicontrol('Parent',t2,'Style','text','Units','normalized', ...
        'Position',[0.03 0.85 0.94 0.045],'String','Circular local map centered at the selected IV', ...
        'FontName',FN,'FontSize',9,'BackgroundColor',BP,'ForegroundColor',[.75 .78 .86], ...
        'HorizontalAlignment','center');
    locAx = axes('Parent',t2,'Units','normalized','Position',[0.05 0.03 0.90 0.80], ...
        'Color',[.1 .1 .14],'XTick',[],'YTick',[]); axis(locAx,'off');
    text(locAx,0.5,0.5,'Select an IV','Units','normalized', ...
        'HorizontalAlignment','center','Color',[.45 .48 .58],'FontSize',11);

    % ---- OR-3  Auto-Align ----
    t3 = uitab(tg,'Title','OR3:AutoAlign','BackgroundColor',BP);
    btn(t3,[0.03 0.90 0.94 0.08],'✨ Auto-Add IV (detect road angle)',FN,BA,[1 1 1], ...
        @(~,~)onAutoAddIV(fig));
    btn(t3,[0.03 0.80 0.46 0.08],'🧭 Head-Up View',FN,BB,[1 1 1],@(~,~)onHeadUp(fig));
    btn(t3,[0.51 0.80 0.46 0.08],'🌍 Normal View',FN,BB,[1 1 1],@(~,~)onNormalView(fig));
    or3Info = uicontrol('Parent',t3,'Style','text','Units','normalized', ...
        'Position',[0.03 0.68 0.94 0.10],'String','Auto-align: detects road direction', ...
        'FontName',FN,'FontSize',10,'BackgroundColor',BP,'ForegroundColor',FL, ...
        'HorizontalAlignment','center');

    % ---- OR-4  Street View ----
    t4 = uitab(tg,'Title','OR4:StreetView','BackgroundColor',BP);
    btn(t4,[0.03 0.90 0.94 0.08],'📸 Generate',FN,BA,[1 1 1],@(~,~)onStreetViewBtn(fig));
    svAx = axes('Parent',t4,'Units','normalized','Position',[0.03 0.03 0.94 0.87], ...
        'Color',[.1 .1 .14],'XTick',[],'YTick',[]); axis(svAx,'off');
    text(svAx,0.5,0.5,'Click a road point','Units','normalized', ...
        'HorizontalAlignment','center','Color',[.45 .48 .58],'FontSize',11);

    % ---- OR-5  Path Plan ----
    t5 = uitab(tg,'Title','OR5:PathPlan','BackgroundColor',BP);
    btn(t5,[0.03 0.90 0.46 0.08],'📍 Start Path',FN,BA,[1 1 1],@(~,~)onPathBtn(fig));
    btn(t5,[0.51 0.90 0.46 0.08],'🗑️ Clear',FN,[.6 .3 .3],[1 1 1],@(~,~)onPathClear(fig));
    pathInfo = uicontrol('Parent',t5,'Style','text','Units','normalized', ...
        'Position',[0.03 0.75 0.94 0.12],'String','Click two points to find the shortest road path.', ...
        'FontName',FN,'FontSize',10,'BackgroundColor',BP,'ForegroundColor',FL, ...
        'HorizontalAlignment','center');

% =====================================================================
%  6.  STATUS BAR
% =====================================================================
    stBar = uicontrol('Parent',fig,'Style','text','Units','normalized', ...
        'Position',[0.005 0.005 0.99 0.048], ...
        'BackgroundColor',[.14 .16 .21],'ForegroundColor',FO, ...
        'FontName',FN,'FontSize',12,'FontWeight','bold','HorizontalAlignment','left', ...
        'String','  Ready.  Click on the map to display real-world coordinates.');

% =====================================================================
%  7.  STATE
% =====================================================================
    s = struct();
    s.ProjectRoot   = projectRoot;
    s.MapImage      = mapImage;   s.MapHeight = mapH;  s.MapWidth = mapW;
    s.Scale         = 1.7;        s.RoadMask = roadMask;
    s.RotationAngle = 0;          s.RotatedImage = mapImage;
    s.OrigCenter    = [(mapW+1)/2 (mapH+1)/2];
    s.RotCenter     = s.OrigCenter;
    s.InteractiveMode = 'idle';
    s.IVList        = [];         s.NextIVID = 1;
    s.SelectedIVIdx = 0;          s.HoveredIVIdx = 0;          s.TempPoints    = [];
    % OR-1
    s.SkelWorldPts  = [];         s.SkelPixPts = [];
    % OR-5
    s.PathPixels    = [];         s.PathWorldPts = [];
    s.ShowLocalDirection = false;
    % handles
    s.Figure = fig;   s.MapAxes = mapAx;  s.hImg = hImg;
    s.StatusBar = stBar;  s.ModeLabel = modeL;
    s.CoordDisp = coordDisp;
    s.AngleInput = angIn; s.ScaleInput = scIn;
    s.IVListbox = ivLB;   s.DistResult = dR;  s.TrajResult = tR;
    s.RotAngleInput = rotIn;
    s.RangeInput = rgIn;  s.LocalAxes = locAx;
    s.LocalDirectionBtn = dirBtn;
    s.LocalInfo = localInfo;
    s.SkelInfo = skelInfo; s.SkelAxes = skelAx;
    s.OR3Info = or3Info;
    s.SVAxes = svAx;
    s.PathInfo = pathInfo;
    s.ContextMenu = cmenu;
    s.ClickCB = @(~,~) onMapClick(fig);
    setappdata(fig,'AppState',s);
    set(hImg,'ButtonDownFcn',s.ClickCB);
    set(fig, 'WindowButtonMotionFcn', @(~,~) onMouseMove(fig));
    app = s;
end

% #####################################################################
%  CALLBACKS
% #####################################################################

function onMapClick(fig)
    s = getappdata(fig,'AppState');
    cp = get(s.MapAxes,'CurrentPoint');
    cC = cp(1,1); cR = cp(1,2);
    [dH,dW,~] = size(s.RotatedImage);
    if cC<0.5||cC>dW+0.5||cR<0.5||cR>dH+0.5, return; end
    if abs(s.RotationAngle)>0.001
        [oR,oC] = r2o(cR,cC,s);
    else, oR=cR; oC=cC;
    end
    if oR<1||oR>s.MapHeight||oC<1||oC>s.MapWidth
        setSt(fig,'  Outside map bounds.',[1 .6 .3]); return;
    end
    [wx,wy] = pixel_to_world(round(oR),round(oC),s.MapHeight,s.Scale);

    clickedIVIdx = check_iv_click(wx, wy, s.IVList);
    clickedIVStr = '';
    if clickedIVIdx > 0
        clickedIVStr = sprintf(' on IV #%d', s.IVList(clickedIVIdx).ID);
        s.SelectedIVIdx = clickedIVIdx;
        set(s.IVListbox, 'Value', clickedIVIdx);
        if strcmp(s.InteractiveMode, 'idle')
            setappdata(fig, 'AppState', s);
            refreshDisp(fig);
            s = getappdata(fig, 'AppState');
        else
            setappdata(fig, 'AppState', s);
            updateLocalView(fig);
        end
    else
        % 当选中车时，如果点击地图别的地方，状态从选中交互变回默认状态
        if s.SelectedIVIdx ~= 0
            s.SelectedIVIdx = 0;
            if strcmp(s.InteractiveMode, 'idle')
                setappdata(fig, 'AppState', s);
                refreshDisp(fig);
                s = getappdata(fig, 'AppState');
            else
                setappdata(fig, 'AppState', s);
                updateLocalView(fig);
            end
        end
    end


    switch s.InteractiveMode
    case 'idle'
        if clickedIVIdx > 0
            setSt(fig,sprintf('  Clicked on IV #%d at X=%.1f m, Y=%.1f m', ...
                s.IVList(clickedIVIdx).ID, wx, wy),[.55 .85 .60]);
        else
            setSt(fig,sprintf('  Position: X=%.1f m, Y=%.1f m  |  Pixel(%d,%d)', ...
                wx,wy,round(oC),round(oR)),[.55 .85 .60]);
        end
        if isfield(s, 'CoordDisp') && isgraphics(s.CoordDisp)
            set(s.CoordDisp,'String',sprintf('X=%.1f m   Y=%.1f m',wx,wy));
        end

    case 'add_iv'
        if clickedIVIdx > 0
            setSt(fig,sprintf('  Cannot place IV here: Area occupied by IV #%d', s.IVList(clickedIVIdx).ID),[1 .4 .4]);
            return;
        end
        if is_on_road(round(oR),round(oC),s.RoadMask)
            a=str2double(get(s.AngleInput,'String')); if isnan(a),a=0;end
            sf=str2double(get(s.ScaleInput,'String')); if isnan(sf)||sf<=0,sf=1;end
            niv=create_iv(s.NextIVID,wx,wy,a,sf);
            if isempty(s.IVList),s.IVList=niv;else,s.IVList(end+1)=niv;end
            s.NextIVID=s.NextIVID+1; s.InteractiveMode='idle';
            s.SelectedIVIdx = 0; % 新加车默认不带光圈
            set(s.ModeLabel,'String','Mode: Idle','ForegroundColor',[.55 .85 .60]);
            setappdata(fig,'AppState',s); refreshDisp(fig); updateIVLB(fig);
            s = getappdata(fig,'AppState');
            setSt(fig,sprintf('  IV #%d at (%.1f,%.1f) angle=%.1f',niv.ID,wx,wy,a),[.4 .9 .5]);
        else
            flashError(fig,'  Not on road! Click a road area.');
        end; return;

    case 'add_iv_auto'
        if clickedIVIdx > 0
            setSt(fig,sprintf('  Cannot place IV here: Area occupied by IV #%d', s.IVList(clickedIVIdx).ID),[1 .4 .4]);
            return;
        end
        if is_on_road(round(oR),round(oC),s.RoadMask)
            a=find_road_direction(round(oR),round(oC),s.RoadMask);
            sf=str2double(get(s.ScaleInput,'String')); if isnan(sf)||sf<=0,sf=1;end
            niv=create_iv(s.NextIVID,wx,wy,a,sf);
            if isempty(s.IVList),s.IVList=niv;else,s.IVList(end+1)=niv;end
            s.NextIVID=s.NextIVID+1; s.InteractiveMode='idle';
            s.SelectedIVIdx = 0; % 新加车默认不带光圈
            set(s.ModeLabel,'String','Mode: Idle','ForegroundColor',[.55 .85 .60]);
            set(s.OR3Info,'String',sprintf('Auto angle: %.1f deg',a));
            setappdata(fig,'AppState',s); refreshDisp(fig); updateIVLB(fig);
            s = getappdata(fig,'AppState');
            setSt(fig,sprintf('  IV #%d auto-aligned at %.1f deg',niv.ID,a),[.4 .9 .5]);
        else
            flashError(fig,'  Not on road!');
        end; return;

    case 'measure_dist'
        % P8: snap to nearest IV if within 15m
        [wx,wy,cC,cR] = snapToIV(s,wx,wy,cC,cR,15);
        s.TempPoints=[s.TempPoints; wx wy cC cR];
        n=size(s.TempPoints,1);
        hold(s.MapAxes,'on');
        hm=plot(s.MapAxes,cC,cR,'ro','MarkerSize',10,'LineWidth',2,'MarkerFaceColor',[1 .3 .3]);
        set(hm,'HitTest','off');
        if n==1
            if clickedIVIdx > 0
                setSt(fig,sprintf('  Pt1:(%.1f,%.1f)%s click 2nd...',wx,wy,clickedIVStr),[1 .8 .3]);
            else
                setSt(fig,sprintf('  Pt1:(%.1f,%.1f) click 2nd...',wx,wy),[1 .8 .3]);
            end
        else
            p1=s.TempPoints(1,:); p2=s.TempPoints(2,:);
            d=sqrt((p2(1)-p1(1))^2+(p2(2)-p1(2))^2);
            hl=plot(s.MapAxes,[p1(3) p2(3)],[p1(4) p2(4)],'r-','LineWidth',2);set(hl,'HitTest','off');
            ht=text(s.MapAxes,(p1(3)+p2(3))/2,(p1(4)+p2(4))/2-15, ...
                sprintf('%.1f m',d),'Color','w','FontSize',10,'FontWeight','bold', ...
                'BackgroundColor',[.8 .15 .15],'HorizontalAlignment','center');
            set(ht,'HitTest','off');
            set(s.DistResult,'String',sprintf('Dist: %.2f m',d));
            if clickedIVIdx > 0
                setSt(fig,sprintf('  Distance = %.2f m (to IV #%d)',d,s.IVList(clickedIVIdx).ID),[.4 .9 .5]);
            else
                setSt(fig,sprintf('  Distance = %.2f m',d),[.4 .9 .5]);
            end
            s.InteractiveMode='idle'; s.TempPoints=[];
            set(s.ModeLabel,'String','Mode: Idle','ForegroundColor',[.55 .85 .60]);
        end
        hold(s.MapAxes,'off');

    case 'measure_traj'
        s.TempPoints=[s.TempPoints; wx wy cC cR];
        n=size(s.TempPoints,1);
        hold(s.MapAxes,'on');
        hm=plot(s.MapAxes,cC,cR,'bs','MarkerSize',8,'LineWidth',2,'MarkerFaceColor',[.3 .5 1]);
        set(hm,'HitTest','off');
        if n>=2
            hl=plot(s.MapAxes,[s.TempPoints(n-1,3) cC],[s.TempPoints(n-1,4) cR],'b-','LineWidth',2);
            set(hl,'HitTest','off');
        end
        hold(s.MapAxes,'off');
        tLen=0;
        for k=2:n,dx=s.TempPoints(k,1)-s.TempPoints(k-1,1);dy=s.TempPoints(k,2)-s.TempPoints(k-1,2);
            tLen=tLen+sqrt(dx^2+dy^2);end
        set(s.TrajResult,'String',sprintf('Traj: %.2f m',tLen));
        if clickedIVIdx > 0
            setSt(fig,sprintf('  Trajectory pt on IV #%d: %d pts, %.2f m',s.IVList(clickedIVIdx).ID,n,tLen),[.3 .7 1]);
        else
            setSt(fig,sprintf('  Trajectory: %d pts, %.2f m',n,tLen),[.3 .7 1]);
        end

    case 'skeleton'
        if is_on_road(round(oR),round(oC),s.RoadMask)
            s.SkelWorldPts=[s.SkelWorldPts; wx wy];
            s.SkelPixPts=[s.SkelPixPts; round(oR) round(oC)];
            n=size(s.SkelWorldPts,1);
            hold(s.MapAxes,'on');
            hm=plot(s.MapAxes,cC,cR,'go','MarkerSize',8,'LineWidth',2,'MarkerFaceColor','g');
            set(hm,'HitTest','off');
            if n>=2
                [~,pc1]=world_to_pixel(s.SkelWorldPts(n-1,1),s.SkelWorldPts(n-1,2),s.MapHeight,s.Scale);
                [~,pc2]=world_to_pixel(wx,wy,s.MapHeight,s.Scale);
                pr1=s.SkelPixPts(n-1,1); pr2=round(oR);
                if abs(s.RotationAngle)>0.001
                    [~,pc1]=o2r(pr1,pc1,s); [~,pc2]=o2r(pr2,pc2,s);
                    [pr1,~]=o2r(s.SkelPixPts(n-1,1),s.SkelPixPts(n-1,2),s);
                    [pr2,~]=o2r(round(oR),round(oC),s);
                end
                hl=plot(s.MapAxes,[pc1 cC],[pr1 cR],'g-','LineWidth',3);set(hl,'HitTest','off');
            end
            hold(s.MapAxes,'off');
            set(s.SkelInfo,'String',sprintf('Points: %d',n));
            if clickedIVIdx > 0
                setSt(fig,sprintf('  Skeleton pt %d: (%.1f,%.1f)%s',n,wx,wy,clickedIVStr),[.4 .9 .5]);
            else
                setSt(fig,sprintf('  Skeleton pt %d: (%.1f,%.1f)',n,wx,wy),[.4 .9 .5]);
            end
        else
            flashError(fig,'  Not on road!');
        end

    case 'street_view'
        if is_on_road(round(oR),round(oC),s.RoadMask)
            if clickedIVIdx > 0
                setSt(fig,sprintf('  Generating street view at IV #%d...',s.IVList(clickedIVIdx).ID),[1 .8 .3]); drawnow;
            else
                setSt(fig,'  Generating street view...',[1 .8 .3]); drawnow;
            end
            ang=find_road_direction(round(oR),round(oC),s.RoadMask);
            svImg=generate_street_view(s.MapImage,round(oR),round(oC),ang,s.MapHeight,s.Scale);
            cla(s.SVAxes); imshow(svImg,'Parent',s.SVAxes);
            title(s.SVAxes,sprintf('Street View  angle=%.0f',ang),'Color',[.85 .88 .95],'FontSize',9);
            s.InteractiveMode='idle';
            set(s.ModeLabel,'String','Mode: Idle','ForegroundColor',[.55 .85 .60]);
            setSt(fig,'  Street view generated.',[.4 .9 .5]);
        else
            flashError(fig,'  Not on road!');
        end

    case 'path_plan'
        s.TempPoints=[s.TempPoints; wx wy cC cR oR oC];
        n=size(s.TempPoints,1);
        hold(s.MapAxes,'on');
        hm=plot(s.MapAxes,cC,cR,'m^','MarkerSize',12,'LineWidth',2,'MarkerFaceColor','m');
        set(hm,'HitTest','off'); hold(s.MapAxes,'off');
        if n==1
            if clickedIVIdx > 0
                setSt(fig,sprintf('  Start set at IV #%d. Click destination.',s.IVList(clickedIVIdx).ID),[1 .8 .3]);
                set(s.PathInfo,'String',sprintf('Start set at IV #%d.',s.IVList(clickedIVIdx).ID));
            else
                setSt(fig,sprintf('  Start: (%.1f,%.1f) click destination...',wx,wy),[1 .8 .3]);
                set(s.PathInfo,'String','Start set. Click destination.');
            end
        else
            if clickedIVIdx > 0
                setSt(fig,sprintf('  Computing shortest path to IV #%d...',s.IVList(clickedIVIdx).ID),[1 .8 .3]); drawnow;
            else
                setSt(fig,'  Computing shortest path...',[1 .8 .3]); drawnow;
            end
            [rr1,rc1]=find_nearest_road(round(s.TempPoints(1,5)),round(s.TempPoints(1,6)),s.RoadMask);
            [rr2,rc2]=find_nearest_road(round(s.TempPoints(2,5)),round(s.TempPoints(2,6)),s.RoadMask);
            [pR,pC]=road_path_bfs(s.RoadMask,rr1,rc1,rr2,rc2);
            if isempty(pR)
                flashError(fig,'  No path found! The two points may not be connected by road.');
                set(s.PathInfo,'String','No path found (unreachable).');
            else
                s.PathPixels=[pR pC];
                pLen=0;
                for k=2:length(pR)
                    [w1x,w1y]=pixel_to_world(pR(k-1),pC(k-1),s.MapHeight,s.Scale);
                    [w2x,w2y]=pixel_to_world(pR(k),pC(k),s.MapHeight,s.Scale);
                    pLen=pLen+sqrt((w2x-w1x)^2+(w2y-w1y)^2);
                end
                set(s.PathInfo,'String',sprintf('Path: %.1f m  (%d px)',pLen,length(pR)));
                setSt(fig,sprintf('  Shortest path = %.1f m',pLen),[.4 .9 .5]);
                setappdata(fig,'AppState',s); refreshDisp(fig);
                s = getappdata(fig,'AppState');
            end
            s.InteractiveMode='idle'; s.TempPoints=[];
            set(s.ModeLabel,'String','Mode: Idle','ForegroundColor',[.55 .85 .60]);
        end
    end
    setappdata(fig,'AppState',s);
end

% ---------- Button callbacks ----------

function onAddIV(fig)
    clearIVSelection(fig);
    s=getappdata(fig,'AppState'); s.InteractiveMode='add_iv'; s.TempPoints=[];
    set(s.ModeLabel,'String','Mode: ADD IV','ForegroundColor',[.25 .55 .85]);
    setappdata(fig,'AppState',s); setSt(fig,'  Click a road to place IV.',[1 .8 .3]);
end
function onRemoveIV(fig)
    clearIVSelection(fig);
    s=getappdata(fig,'AppState');
    if isempty(s.IVList),setSt(fig,'  No IVs.',[1 .4 .4]);return;end
    sel=get(s.IVListbox,'Value');
    if sel<1||sel>length(s.IVList),setSt(fig,'  Select an IV.',[1 .4 .4]);return;end
    rid=s.IVList(sel).ID; s.IVList(sel)=[];
    s.SelectedIVIdx = 0; % 移除当前选中的小车状态
    if isempty(s.IVList)
        set(s.IVListbox,'Value',1);
    else
        set(s.IVListbox,'Value',min(sel,length(s.IVList)));
    end
    setappdata(fig,'AppState',s); refreshDisp(fig); updateIVLB(fig);
    s = getappdata(fig,'AppState');
    setSt(fig,sprintf('  IV #%d removed.',rid),[.4 .9 .5]);
end
function onReportIV(fig)
    clearIVSelection(fig);
    s=getappdata(fig,'AppState');
    if isempty(s.IVList)
        errordlg('No IVs loaded on the map. Please add some IVs first.','Report Error','modal');
        return;
    end
    
    n = length(s.IVList);
    
    % ---- 创建现代深色模态对话框 ----
    ss = get(0,'ScreenSize');
    dw = 550; dh = 320;
    dfig = figure('Name','IV Positions Summary Report','NumberTitle','off', ...
        'Color',[.18 .20 .25],'MenuBar','none','ToolBar','none', ...
        'Position',[(ss(3)-dw)/2 (ss(4)-dh)/2 dw dh],'Resize','off', ...
        'WindowStyle','modal');
        
    % ---- 顶部标题 ----
    uicontrol('Parent',dfig,'Style','text','Units','normalized', ...
        'Position',[0.03 0.88 0.94 0.08],'String','INTELLIGENT VEHICLE STATE REPORT', ...
        'FontName','Segoe UI','FontSize',11,'FontWeight','bold', ...
        'BackgroundColor',[.18 .20 .25],'ForegroundColor',[.55 .85 .60], ...
        'HorizontalAlignment','center');
        
    % ---- 构建表格数据 ----
    colNames = {'IV ID', 'X (meters)', 'Y (meters)', 'Heading (deg)', 'Scale Factor', 'Pixel (C, R)'};
    data = cell(n, 6);
    for k = 1:n
        iv = s.IVList(k);
        % 利用 world_to_pixel 计算小车原图像素坐标
        [pr, pc] = world_to_pixel(iv.WorldX, iv.WorldY, s.MapHeight, s.Scale);
        data{k, 1} = sprintf('IV #%d', iv.ID);
        data{k, 2} = sprintf('%.1f m', iv.WorldX);
        data{k, 3} = sprintf('%.1f m', iv.WorldY);
        data{k, 4} = sprintf('%.1f deg', iv.Angle);
        data{k, 5} = sprintf('%.2f', iv.ScaleFactor);
        data{k, 6} = sprintf('(%d, %d)', pc, pr);
    end
    
    % ---- 创建现代 uitable 表格 ----
    uitable('Parent',dfig,'Units','normalized', ...
        'Position',[0.05 0.22 0.90 0.62], ...
        'Data',data,'ColumnName',colNames, ...
        'ColumnWidth',{60, 95, 95, 95, 80, 90}, ...
        'RowName',[], ...
        'BackgroundColor',[.24 .26 .32; .28 .30 .36], ...
        'ForegroundColor',[.95 .95 .98]);
        
    % ---- 底部汇总信息与关闭按钮 ----
    summaryStr = sprintf('Total Active IVs: %d  |  Coordinate System: Bottom-Left (0,0)', n);
    uicontrol('Parent',dfig,'Style','text','Units','normalized', ...
        'Position',[0.05 0.08 0.65 0.08], ...
        'String',summaryStr,'FontName','Segoe UI','FontSize',9, ...
        'BackgroundColor',[.18 .20 .25],'ForegroundColor',[.85 .88 .95], ...
        'HorizontalAlignment','left');
        
    uicontrol('Parent',dfig,'Style','pushbutton','Units','normalized', ...
        'Position',[0.75 0.06 0.20 0.11], ...
        'String','Close','FontName','Segoe UI','FontSize',9,'FontWeight','bold', ...
        'BackgroundColor',[.25 .55 .85],'ForegroundColor',[1 1 1], ...
        'Callback',@(~,~)delete(dfig));
        
    setSt(fig,sprintf('  Reported %d IVs via summary table.',n),[.4 .9 .5]);
end
function onDistBtn(fig)
    clearIVSelection(fig);
    s=getappdata(fig,'AppState'); s.InteractiveMode='measure_dist'; s.TempPoints=[];
    set(s.ModeLabel,'String','Mode: DISTANCE','ForegroundColor',[1 .45 .45]);
    setappdata(fig,'AppState',s); setSt(fig,'  Click first point...',[1 .8 .3]);
end
function onTrajBtn(fig)
    clearIVSelection(fig);
    s=getappdata(fig,'AppState'); s.InteractiveMode='measure_traj'; s.TempPoints=[];
    set(s.ModeLabel,'String','Mode: TRAJECTORY','ForegroundColor',[.3 .7 1]);
    setappdata(fig,'AppState',s); setSt(fig,'  Click points to build trajectory...',[1 .8 .3]);
end
function onClearMeas(fig)
    clearIVSelection(fig);
    s=getappdata(fig,'AppState'); s.InteractiveMode='idle'; s.TempPoints=[];
    set(s.ModeLabel,'String','Mode: Idle','ForegroundColor',[.55 .85 .60]);
    set(s.DistResult,'String','Dist: --'); set(s.TrajResult,'String','Traj: --');
    setappdata(fig,'AppState',s); refreshDisp(fig); setSt(fig,'  Cleared.',[.55 .85 .60]);
end
function onRotate(fig)
    clearIVSelection(fig);
    s=getappdata(fig,'AppState');
    a=str2double(get(s.RotAngleInput,'String'));
    if isnan(a),setSt(fig,'  Invalid angle.',[1 .4 .4]);return;end
    setSt(fig,'  Rotating...',[1 .8 .3]); drawnow;
    s.RotationAngle=a;
    if abs(a)<0.001, s.RotatedImage=s.MapImage; s.RotCenter=s.OrigCenter;
    else,[ri,nh,nw]=rotate_map(s.MapImage,a); s.RotatedImage=ri; s.RotCenter=[(nw+1)/2 (nh+1)/2];end
    setappdata(fig,'AppState',s); refreshDisp(fig);
    setSt(fig,sprintf('  Rotated %.1f deg.',a),[.4 .9 .5]);
end

% ---------- OR-1 Skeleton ----------
function onSkelExtract(fig)
    clearIVSelection(fig);
    s=getappdata(fig,'AppState'); s.InteractiveMode='skeleton'; s.TempPoints=[];
    set(s.ModeLabel,'String','Mode: SKELETON','ForegroundColor',[.3 .85 .4]);
    setappdata(fig,'AppState',s); setSt(fig,'  Click road points to extract skeleton...',[1 .8 .3]);
end
function onSkelEnd(fig)
    clearIVSelection(fig);
    s=getappdata(fig,'AppState'); s.InteractiveMode='idle';
    set(s.ModeLabel,'String','Mode: Idle','ForegroundColor',[.55 .85 .60]);
    setappdata(fig,'AppState',s);
    setSt(fig,sprintf('  Skeleton: %d pts.',size(s.SkelWorldPts,1)),[.4 .9 .5]);
end
function onSkelClear(fig)
    clearIVSelection(fig);
    s=getappdata(fig,'AppState');
    s.SkelWorldPts=[]; s.SkelPixPts=[]; s.InteractiveMode='idle';
    set(s.ModeLabel,'String','Mode: Idle','ForegroundColor',[.55 .85 .60]);
    set(s.SkelInfo,'String','Points: 0');
    cla(s.SkelAxes); 
    set(s.SkelAxes, 'Position', [0.05 0.02 0.90 0.70]);
    axis(s.SkelAxes,'off');
    setappdata(fig,'AppState',s); refreshDisp(fig); setSt(fig,'  Skeleton cleared.',[.55 .85 .60]);
end
function onSkelShow(fig)
    clearIVSelection(fig);
    s=getappdata(fig,'AppState');
    if size(s.SkelWorldPts,1)<2,setSt(fig,'  Need >= 2 skeleton points.',[1 .4 .4]);return;end
    cla(s.SkelAxes);
    set(s.SkelAxes, 'Position', [0.15 0.14 0.74 0.52]);
    plot(s.SkelAxes, s.SkelWorldPts(:,1), s.SkelWorldPts(:,2), 'g-o', ...
        'LineWidth',2,'MarkerSize',6,'MarkerFaceColor','g');
    set(s.SkelAxes,'Color',[.12 .12 .16],'XColor',[.6 .6 .7],'YColor',[.6 .6 .7]);
    xlabel(s.SkelAxes,'X (m)','Color',[.7 .7 .8]);
    ylabel(s.SkelAxes,'Y (m)','Color',[.7 .7 .8]);
    title(s.SkelAxes,'Road Skeleton (world)','Color',[.85 .88 .95],'FontSize',9);
    axis(s.SkelAxes,'on');
    axis(s.SkelAxes,'equal');
    setSt(fig,'  Skeleton displayed in world coordinates.',[.4 .9 .5]);
end
function onSkelRoadArea(fig)
    clearIVSelection(fig);
    s=getappdata(fig,'AppState');
    if size(s.SkelPixPts,1)<2,setSt(fig,'  Need >= 2 skeleton points.',[1 .4 .4]);return;end
    setSt(fig,'  Computing road area near skeleton...',[1 .8 .3]); drawnow;
    [H,W]=size(s.RoadMask); nearMask=false(H,W); radius=30;
    sp=s.SkelPixPts;
    for i=1:size(sp,1)-1
        r1=sp(i,1);c1=sp(i,2);r2=sp(i+1,1);c2=sp(i+1,2);
        nS=max(abs(r2-r1),abs(c2-c1)); if nS==0,nS=1;end
        for step=0:nS
            t=step/nS; pr=round(r1+t*(r2-r1)); pc=round(c1+t*(c2-c1));
            rMi=max(1,pr-radius);rMa=min(H,pr+radius);
            cMi=max(1,pc-radius);cMa=min(W,pc+radius);
            [cc,rr]=meshgrid(cMi:cMa,rMi:rMa);
            nearMask(rMi:rMa,cMi:cMa)=nearMask(rMi:rMa,cMi:cMa)|((rr-pr).^2+(cc-pc).^2<=radius^2);
        end
    end
    roadArea=s.RoadMask & nearMask; mi=s.MapImage;
    for ch=1:3,chan=mi(:,:,ch);chan(~roadArea)=0;mi(:,:,ch)=chan;end
    cla(s.SkelAxes); 
    set(s.SkelAxes, 'Position', [0.05 0.02 0.90 0.70]);
    axis(s.SkelAxes, 'off');
    imshow(mi,'Parent',s.SkelAxes);
    title(s.SkelAxes,'Road Area near Skeleton','Color',[.85 .88 .95],'FontSize',9);
    setSt(fig,'  Road area extracted.',[.4 .9 .5]);
end

% ---------- OR-3 Auto-Align ----------
function onAutoAddIV(fig)
    clearIVSelection(fig);
    s=getappdata(fig,'AppState'); s.InteractiveMode='add_iv_auto'; s.TempPoints=[];
    set(s.ModeLabel,'String','Mode: AUTO-ADD IV','ForegroundColor',[.25 .55 .85]);
    setappdata(fig,'AppState',s); setSt(fig,'  Click road - angle auto-detected.',[1 .8 .3]);
end
function onHeadUp(fig)
    s=getappdata(fig,'AppState');
    if isempty(s.IVList),setSt(fig,'  No IVs.',[1 .4 .4]);return;end
    sel=get(s.IVListbox,'Value');
    if sel<1||sel>length(s.IVList),sel=1;end
    iv=s.IVList(sel); a=90-iv.Angle;
    set(s.RotAngleInput,'String',sprintf('%.1f',a));
    s.RotationAngle=a;
    if abs(a)<0.001, s.RotatedImage=s.MapImage; s.RotCenter=s.OrigCenter;
    else,[ri,~,nw]=rotate_map(s.MapImage,a); s.RotatedImage=ri;
        [nh2,nw2,~]=size(ri); s.RotCenter=[(nw2+1)/2 (nh2+1)/2];end
    setappdata(fig,'AppState',s); refreshDisp(fig);
    setSt(fig,sprintf('  Head-up view for IV #%d (rot=%.1f)',iv.ID,a),[.4 .9 .5]);
    clearIVSelection(fig);
end
function onNormalView(fig)
    clearIVSelection(fig);
    s=getappdata(fig,'AppState'); s.RotationAngle=0;
    s.RotatedImage=s.MapImage; s.RotCenter=s.OrigCenter;
    set(s.RotAngleInput,'String','0');
    setappdata(fig,'AppState',s); refreshDisp(fig); setSt(fig,'  Normal view.',[.55 .85 .60]);
end

% ---------- OR-4 Street View ----------
function onStreetViewBtn(fig)
    clearIVSelection(fig);
    s=getappdata(fig,'AppState'); s.InteractiveMode='street_view'; s.TempPoints=[];
    set(s.ModeLabel,'String','Mode: STREET VIEW','ForegroundColor',[.8 .6 .2]);
    setappdata(fig,'AppState',s); setSt(fig,'  Click a road point for street view.',[1 .8 .3]);
end

% ---------- OR-5 Path Planning ----------
function onPathBtn(fig)
    clearIVSelection(fig);
    s=getappdata(fig,'AppState'); s.InteractiveMode='path_plan'; s.TempPoints=[];
    s.PathPixels=[];
    set(s.ModeLabel,'String','Mode: PATH PLAN','ForegroundColor',[.85 .4 .85]);
    setappdata(fig,'AppState',s); refreshDisp(fig);
    set(s.PathInfo,'String','Click start point...'); setSt(fig,'  Click start point.',[1 .8 .3]);
end
function onPathClear(fig)
    clearIVSelection(fig);
    s=getappdata(fig,'AppState'); s.PathPixels=[]; s.TempPoints=[];
    s.InteractiveMode='idle';
    set(s.ModeLabel,'String','Mode: Idle','ForegroundColor',[.55 .85 .60]);
    set(s.PathInfo,'String','Click two points to find the shortest road path.');
    setappdata(fig,'AppState',s); refreshDisp(fig); setSt(fig,'  Path cleared.',[.55 .85 .60]);
end

% #####################################################################
%  DISPLAY
% #####################################################################

function refreshDisp(fig)
    s=getappdata(fig,'AppState');
    cla(s.MapAxes);
    hI=imshow(s.RotatedImage,'Parent',s.MapAxes);
    set(hI,'ButtonDownFcn',s.ClickCB);
    % Re-apply context menu to new image (P9)
    if isfield(s,'ContextMenu') && isvalid(s.ContextMenu)
        set(hI,'UIContextMenu',s.ContextMenu);
    end
    hold(s.MapAxes,'on');
    oc=s.OrigCenter; rc=s.RotCenter;
    % IVs — pass click callback for IV click-to-select (P3)
    for k=1:length(s.IVList)
        draw_iv(s.MapAxes,s.IVList(k),s.MapHeight,s.Scale,s.RotationAngle,oc,rc, k==s.SelectedIVIdx, k==s.HoveredIVIdx);
    end
    % Skeleton overlay
    if size(s.SkelPixPts,1)>=2
        sc=s.SkelPixPts(:,2); sr=s.SkelPixPts(:,1);
        if abs(s.RotationAngle)>0.001
            for j=1:length(sc),[sr(j),sc(j)]=o2r(s.SkelPixPts(j,1),s.SkelPixPts(j,2),s);end
        end
        hs=plot(s.MapAxes,sc,sr,'g-','LineWidth',3);set(hs,'HitTest','off');
        hd=plot(s.MapAxes,sc,sr,'go','MarkerSize',5,'MarkerFaceColor','g');set(hd,'HitTest','off');
    end
    % Path overlay
    if ~isempty(s.PathPixels) && size(s.PathPixels,1)>=2
        step=max(1,floor(size(s.PathPixels,1)/800));
        ps=s.PathPixels(1:step:end,:); pc=ps(:,2); pr=ps(:,1);
        if abs(s.RotationAngle)>0.001
            for j=1:length(pc),[pr(j),pc(j)]=o2r(ps(j,1),ps(j,2),s);end
        end
        hp=plot(s.MapAxes,pc,pr,'m-','LineWidth',3);set(hp,'HitTest','off');
    end
    hold(s.MapAxes,'off');
    s.hImg=hI; setappdata(fig,'AppState',s);
    updateLocalView(fig);
end

function updateIVLB(fig)
    s=getappdata(fig,'AppState');
    if isempty(s.IVList)
        set(s.IVListbox,'String',{'(none)'},'Value',1);
        return;
    end
    items=cell(1,length(s.IVList));
    for k=1:length(s.IVList)
        iv=s.IVList(k);
        items{k}=sprintf('#%d (%.0f,%.0f) %g deg',iv.ID,iv.WorldX,iv.WorldY,iv.Angle);
    end
    v = s.SelectedIVIdx;
    if v < 1 || v > length(items)
        v = 1;
    end
    set(s.IVListbox,'String',items,'Value',v);
end

function updateLocalView(fig)
    s=getappdata(fig,'AppState');
    sel=s.SelectedIVIdx;
    if isempty(s.IVList)||sel<1||sel>length(s.IVList)
        cla(s.LocalAxes);axis(s.LocalAxes,'off');
        text(s.LocalAxes,0.5,0.5,'Select an IV','Units','normalized', ...
            'HorizontalAlignment','center','Color',[.45 .48 .58],'FontSize',11);return;
    end
    iv=s.IVList(sel);
    rM=str2double(get(s.RangeInput,'String')); if isnan(rM)||rM<=0,rM=100;end
    [cR,cC]=world_to_pixel(iv.WorldX,iv.WorldY,s.MapHeight,s.Scale);
    rP=rM/s.Scale; li=local_map_view(s.MapImage,cR,cC,rP);
    li=overlayLocalIV(li,iv,s.Scale,s.ShowLocalDirection);
    cla(s.LocalAxes); imshow(li,'Parent',s.LocalAxes);
    title(s.LocalAxes,sprintf('IV#%d R=%.0fm Sc=%g',iv.ID,rM,iv.ScaleFactor), ...
        'Color',[.85 .88 .95],'FontSize',9);
end

function onToggleLocalDirection(fig)
    s = getappdata(fig,'AppState');
    s.ShowLocalDirection = ~s.ShowLocalDirection;
    if s.ShowLocalDirection
        set(s.LocalDirectionBtn,'BackgroundColor',[.15 .15 .15],'ForegroundColor',[1 1 1]);
        set(s.LocalDirectionBtn,'String','Hide Direction');
        setSt(fig,'  OR2 local view: direction arrow shown.',[.55 .85 .60]);
    else
        set(s.LocalDirectionBtn,'BackgroundColor',[0.35 0.38 0.48],'ForegroundColor',[1 1 1]);
        set(s.LocalDirectionBtn,'String','Show Direction');
        setSt(fig,'  OR2 local view: direction arrow hidden.',[.55 .85 .60]);
    end
    setappdata(fig,'AppState',s);
    updateLocalView(fig);
end

% #####################################################################
%  HELPERS
% #####################################################################

function [oR,oC] = r2o(rR,rC,s)
    a=s.RotationAngle*pi/180; ca=cos(a); sa=sin(a);
    dc=rC-s.RotCenter(1); dr=rR-s.RotCenter(2);
    oC=ca*dc-sa*dr+s.OrigCenter(1); oR=sa*dc+ca*dr+s.OrigCenter(2);
end
function [rR,rC] = o2r(oR,oC,s)
    a=s.RotationAngle*pi/180; ca=cos(a); sa=sin(a);
    dc=oC-s.OrigCenter(1); dr=oR-s.OrigCenter(2);
    rC=ca*dc+sa*dr+s.RotCenter(1); rR=-sa*dc+ca*dr+s.RotCenter(2);
end
function setSt(fig,msg,clr)
    s=getappdata(fig,'AppState');set(s.StatusBar,'String',msg,'ForegroundColor',clr);
end
function outImg = overlayLocalIV(img,iv,mapScale,showDirection)
    outImg = img;
    [imgH,imgW,~] = size(outImg);
    centerR = (imgH + 1) / 2;
    centerC = (imgW + 1) / 2;
    halfL = (iv.Length * iv.ScaleFactor) / (2 * mapScale);
    halfW = (iv.Width * iv.ScaleFactor) / (2 * mapScale);
    ang = iv.Angle * pi / 180;
    cosA = cos(ang);
    sinA = sin(ang);
    % Keep the direction marker readable in OR2 and independent of IV scale.
    arrowLen = 14;
    shaftHalfW = 1.8;
    headLen = 5;
    headHalfW = 4.5;
    radius = ceil(max(sqrt(halfL^2 + halfW^2), arrowLen + headHalfW)) + 3;
    rMin = max(1,floor(centerR - radius));
    rMax = min(imgH,ceil(centerR + radius));
    cMin = max(1,floor(centerC - radius));
    cMax = min(imgW,ceil(centerC + radius));
    bodyColor = [60 150 255];
    edgeColor = [255 220 60];
    if nargin < 4
        showDirection = false;
    end
    arrowColor = [0 0 0];
    for r = rMin:rMax
        for c = cMin:cMax
            dx = c - centerC;
            dy = centerR - r;
            u = cosA * dx + sinA * dy;
            v = -sinA * dx + cosA * dy;
            isBody = abs(u) <= halfL && abs(v) <= halfW;
            if abs(u) <= halfL && abs(v) <= halfW
                if abs(abs(u) - halfL) <= 1 || abs(abs(v) - halfW) <= 1
                    outImg(r,c,:) = reshape(uint8(edgeColor),1,1,3);
                else
                    for ch = 1:3
                        baseVal = double(outImg(r,c,ch));
                        mixVal = 0.62 * baseVal + 0.38 * bodyColor(ch);
                        outImg(r,c,ch) = uint8(round(mixVal));
                    end
                end
            end
            if showDirection
                inShaft = (u >= 0) && (u <= arrowLen - headLen) && (abs(v) <= shaftHalfW);
                headBaseU = arrowLen - headLen;
                inHead = (u >= headBaseU) && (u <= arrowLen);
                if inHead
                    vLimit = headHalfW * (arrowLen - u) / max(headLen, 0.1);
                else
                    vLimit = -1;
                end
                if inShaft || (inHead && abs(v) <= vLimit)
                    if ~isBody || u >= halfL * 0.10
                        outImg(r,c,:) = reshape(uint8(arrowColor),1,1,3);
                    end
                end
            end
        end
    end
end
function flashError(fig,msg)
%FLASHERROR  Show error message with flashing red background (P4).
    s=getappdata(fig,'AppState');
    set(s.StatusBar,'String',msg,'ForegroundColor',[1 1 1], ...
        'BackgroundColor',[.75 .15 .15]);
    drawnow;
    pause(0.35);
    set(s.StatusBar,'ForegroundColor',[1 .4 .4], ...
        'BackgroundColor',[.14 .16 .21]);
end
function [wx,wy,cC,cR] = snapToIV(s,wx,wy,cC,cR,thresh)
%SNAPTOIV  If click is within thresh metres of an IV centre, snap to it (P8).
    if isempty(s.IVList), return; end
    bestD = thresh;
    bestK = 0;
    for k=1:length(s.IVList)
        iv=s.IVList(k);
        d=sqrt((wx-iv.WorldX)^2+(wy-iv.WorldY)^2);
        if d<bestD, bestD=d; bestK=k; end
    end
    if bestK>0
        iv=s.IVList(bestK);
        wx=iv.WorldX; wy=iv.WorldY;
        [pR,pC]=world_to_pixel(wx,wy,s.MapHeight,s.Scale);
        if abs(s.RotationAngle)>0.001
            [cR,cC]=o2r(pR,pC,s);
        else
            cC=pC; cR=pR;
        end
    end
end
function onIVClick(fig, ivIdx)
%ONIVCLICK  Handle click on an IV in the map — select it in listbox (P3).
    s=getappdata(fig,'AppState');
    if ivIdx>=1 && ivIdx<=length(s.IVList)
        set(s.IVListbox,'Value',ivIdx);
        iv=s.IVList(ivIdx);
        setSt(fig,sprintf('  Selected IV #%d  (%.1f, %.1f)  angle=%.1f',iv.ID,iv.WorldX,iv.WorldY,iv.Angle),[.3 .7 1]);
        updateLocalView(fig);
    end
end
function lab(p,pos,txt,fn,bg,fg)
    uicontrol('Parent',p,'Style','text','Units','normalized','Position',pos, ...
        'String',txt,'FontName',fn,'FontSize',9,'BackgroundColor',bg,'ForegroundColor',fg, ...
        'HorizontalAlignment','left');
end
function h=btn(p,pos,txt,fn,bg,fg,cb)
    h=uicontrol('Parent',p,'Style','pushbutton','Units','normalized','Position',pos, ...
        'String',txt,'FontName',fn,'FontSize',9,'FontWeight','bold', ...
        'BackgroundColor',bg,'ForegroundColor',fg,'Callback',cb);
end
function sep(p,y,clr)
    uicontrol('Parent',p,'Style','text','Units','normalized', ...
        'Position',[0.03 y 0.94 0.002],'BackgroundColor',clr);
end
function stit(p,y,txt,fn,bg,fg)
    uicontrol('Parent',p,'Style','text','Units','normalized', ...
        'Position',[0.03 y 0.94 0.022],'String',txt, ...
        'FontName',fn,'FontSize',9,'FontWeight','bold', ...
        'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','center');
end

function idx = check_iv_click(wx, wy, ivList)
    idx = 0;
    if isempty(ivList), return; end
    % Check backwards so top-most is selected
    for k = length(ivList):-1:1
        iv = ivList(k);
        dx = wx - iv.WorldX;
        dy = wy - iv.WorldY;
        dist = sqrt(dx^2 + dy^2);
        halfL = (iv.Length * iv.ScaleFactor) / 2;
        % 自适应高精度判定，最小仅 12 米（约 7 像素），紧密贴合方形车身，鼠标没移上绝不触发！
        click_radius = max(12, halfL * 1.5);
        if dist <= click_radius
            idx = k;
            return;
        end
    end
end

function onListboxSelect(fig)
    s = getappdata(fig, 'AppState');
    if isempty(s.IVList)
        s.SelectedIVIdx = 0;
    else
        s.SelectedIVIdx = get(s.IVListbox, 'Value');
    end
    setappdata(fig, 'AppState', s);
    refreshDisp(fig);
end

function onMouseMove(fig)
    s = getappdata(fig, 'AppState');
    if isempty(s) || isempty(s.IVList)
        if ~isempty(s) && s.HoveredIVIdx ~= 0
            s.HoveredIVIdx = 0;
            set(fig, 'Pointer', 'arrow');
            setappdata(fig, 'AppState', s);
            refreshDisp(fig);
        else
            set(fig, 'Pointer', 'arrow');
        end
        return;
    end
    cp = get(s.MapAxes, 'CurrentPoint');
    cC = cp(1,1); cR = cp(1,2);
    [dH,dW,~] = size(s.RotatedImage);
    if cC < 0.5 || cC > dW + 0.5 || cR < 0.5 || cR > dH + 0.5
        if s.HoveredIVIdx ~= 0
            s.HoveredIVIdx = 0;
            set(fig, 'Pointer', 'arrow');
            setappdata(fig, 'AppState', s);
            refreshDisp(fig);
        else
            set(fig, 'Pointer', 'arrow');
        end
        return;
    end
    if abs(s.RotationAngle) > 0.001
        [oR,oC] = r2o(cR,cC,s);
    else
        oR = cR; oC = cC;
    end
    if oR < 1 || oR > s.MapHeight || oC < 1 || oC > s.MapWidth
        if s.HoveredIVIdx ~= 0
            s.HoveredIVIdx = 0;
            set(fig, 'Pointer', 'arrow');
            setappdata(fig, 'AppState', s);
            refreshDisp(fig);
        else
            set(fig, 'Pointer', 'arrow');
        end
        return;
    end
    [wx,wy] = pixel_to_world(round(oR), round(oC), s.MapHeight, s.Scale);
    hoverIdx = check_iv_click(wx, wy, s.IVList);
    
    if hoverIdx ~= s.HoveredIVIdx
        s.HoveredIVIdx = hoverIdx;
        if hoverIdx > 0
            set(fig, 'Pointer', 'hand');
        else
            set(fig, 'Pointer', 'arrow');
        end
        setappdata(fig, 'AppState', s);
        refreshDisp(fig);
    end
end

function clearIVSelection(fig)
    s = getappdata(fig, 'AppState');
    if ~isempty(s) && s.SelectedIVIdx ~= 0
        s.SelectedIVIdx = 0;
        setappdata(fig, 'AppState', s);
        refreshDisp(fig);
    end
end


