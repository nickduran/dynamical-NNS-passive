%% Passive vs Active CoNNStructioNNS (MouseTracker Output)

%% STANDARDIZED CODE FOR TRAJS/ANG ANALYSIS: TAKES AS INPUT: SINGLE TRAJECTORY (x,y) AND TIME STAMPS (t)
% includes the functions trim0 velaj xflip

%%%%%%%%%%%%%%%%%
%% SET PARAMETERS
%%%%%%%%%%%%%%%%%

%%// set the root directory where experiment files/trajectories are included
ROOT = '/Users/nduran/Dropbox (ASU)/ScottProject/activePassive/dataAnalysis2/mt_transformed/';
cd(ROOT);

ESCAPE = 10; % escape region around origin where latency/motion measures begin, in pixels
VELAJBIN = 6; % number of timesteps in which to compute/average velocity

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% INITIALIZING OUTPUT FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%// OUTPUTS DV file
% f1o = fopen('PROCESSED_SUPERNEW.txt','w');
f1o = fopen('delete.txt','w');
fprintf(f1o,'ability\tsubjectN\tsubjectOG\ttrial\tstim\torder\tcondition\tresp_1\tresp_2\tresponse\terror\tresp_num\tRT\tinit_time\tdistractor\t');
fprintf(f1o,'rt\tinitTime\tDV_inmot\tDV_velmax\tDV_velmax_start\t');
fprintf(f1o,'DV_dist\tDV_ADavg\tDV_AUC\tDV_xflp_tot\tDV_ang_tot\n');

%%// OUTPUTS interpolated
f3o = fopen('delete_XY.txt','w');
% f3o = fopen('SUPERNEW_INTER_XY.txt','w');
fprintf(f3o,'ability\tsubjectN\tsubjectOG\ttrial\tstim\torder\tcondition\tresp_1\tresp_2\tresponse\terror\tresp_num\tRT\tinit_time\tdistractor\t');
fprintf(f3o,'timeINT\txINT\tyINT\tangleINT\n');

%%// OUTPUTS velocity profiles
% f4o = fopen('Velocity_ProfilesNNNS.txt','w');
% fprintf(f4o,'subjnum\ttrialnum\tround\topinion\tveracity\tcondition\tcoNNSpAcc\ttopic\tpoliID1\tquestionType\thand\tdevice\tage\tsex\tstimlist\t');
% fprintf(f4o,'velocity\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOAD IN EACH FILE OF INDIVIDUAL TRAJECTORIES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tallyS = 0;

folders = {'ns_clean','nns_clean'};
for mm = 1:2,
    if mm == 1
        subs = 1:99;
    else
        subs = 100:199;
    end
    
    trials = 90;
    tally = 0;
    
    for subj = 1:length(subs), %for subj = 1:length(subs)
                
        subjnum = subs(subj);
        disp(subjnum)
        isCorrect = 0;
        for trial = 1:trials,
%         for trial = 36,    
            f1 = [ROOT folders{mm} '/' num2str(subjnum) '_' int2str(trial) '.txt'];
            if exist(f1,'file') == 2, % proceed if file exists, it should, otherwise we will see problems in main datasheet
                fid = fopen(f1);
                tc = textscan(fid,'%f%f%f%s%s%s%s%s%s%s%s%s%s%s%s','Delimiter','\t');
                tally = tally + 1;
          
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%// SET UP EACH TRAJECTORY BASED ON PARTICIPANT AND CONDITION INFORMATION
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
                if tc{2}(1) == 101, % correcting some issue with MouseTracker where it puts "101" at the initial coordinate
                    y = tc{3}(2:end); 
                    y = -1*(y-y(1));
                    x = tc{2}(2:end);
                    x = x-x(1);
                    t = tc{1}(2:end);
                    
                elseif tc{2}(1) ~= 101,
                    y = -1*(tc{3}-tc{3}(1)); % normalize so all trajs begin at 0
                    x = tc{2}-tc{2}(1); 
                    t = tc{1};                  
                end
                                
                %%// generate quick plots of x,y, trajectories to determine if there are unusual trajectories
%                 figure('Visible','Off')
%                 plot(x,y)
%                 saveas(gcf, [ROOT 'figures/' num2str(subjnum) '_' num2str(trial) '_xy'], 'jpeg');
%                 close all
                
                %%%%%%%%%%%%%%%%%%%%%%%
                %% DEPENDENT VARIABLES
                %%%%%%%%%%%%%%%%%%%%%%%
                try
                    %% TOTAL TIME
                    DV_total_time = t(length(t));

                    %% TOTAL TIME SEPARATE FOR LATENCY, MOTION, DWELL
                    %%%% latency time only %%%%
                    %%%% motion time w/ no latency
                    %%%% dwell time only %%%%
                    [latency_indx,xtrim,ytrim] = trim0(x,y,ESCAPE); % only x,y coordinates after "escaping" an initial N pixel range around the origin of movement
                    DV_latency = t(latency_indx-1); % latency time (ms) - to begin moving
                    DV_inmot = (t(length(t))-DV_latency); % motion time (ms) - motion time w/ no latency; includes dwell
                    
                    %% DISTANCE EUCLIDEAN TOTAL
                    %%%% distance (euclidean) entire length %%%%
                    distx = (x(2:length(x))-x(1:length(x)-1)).^2; % (x2-x1)^2
                    disty = (y(2:length(y))-y(1:length(y)-1)).^2; % (y2-y1)^2
                    DV_dist = sum(sqrt(distx+disty)); % euclidean distance traveled (pixels)

                catch
                    display('problem with generating total time and distance DVs')
                end
                try
                    %% VELOCITY AND ACCELERATION FLIPS
                    %%%% velocity max value; velocity max timing; acceleration %%%%
                    [veloc,accel,jerk] = velaj(t,x,y,VELAJBIN); % within a VELAJBIN window
                    DV_velmax = max(veloc); % maximum velocity
                    DV_velmax_start = t(find(veloc==DV_velmax,1)); % at what point does maximum velocity occur

                catch
                    display('problem with generating velocity DVs')
                end

                try
                    %% AREA UNDER THE CURVE
                    if sign(x(end)) == 1,
                        DV_AUC = trapz(x/max(x),y/max(y));
                    elseif sign(x(end)) == -1,
                        AUCx = x*-1;
                        DV_AUC = trapz(AUCx/max(AUCx),y/max(y));
                    elseif sign(x(end)) == 0,
                        DV_AUC = 999999999999; % corrects incredibly rare situations where there is a problem with trajectories
                    end

                catch
                    display('problem with generating AUC')
                end

                try
                    %% FLIPS ALONG X AND ANGLE FOR LATENCY, MOTION, DWELL
                    %%%% change in direction for angle trajectories (latency, motion, dwell) %%%%
                    DV_xflp_tot = xflip(x); % all x-flips for comparison purposes
                    DV_xflp_mot = xflip(xtrim); % includes dwell

                catch
                    display('problem with generating x-flips')
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %% SAVING DATA AS EXCEL OUTPUT
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                fprintf(f1o,'%d\t%d\t%s\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t',mm,subjnum,cell2mat(tc{4}(1)),trial,cell2mat(tc{5}(1)),cell2mat(tc{6}(1)),cell2mat(tc{7}(1)),cell2mat(tc{8}(1)),cell2mat(tc{9}(1)),cell2mat(tc{10}(1)),cell2mat(tc{11}(1)),cell2mat(tc{12}(1)),cell2mat(tc{13}(1)),cell2mat(tc{14}(1)),cell2mat(tc{15}(1)));
                fprintf(f1o,'%f\t%f\t%f\t%f\t%f\t',DV_total_time, DV_latency, DV_inmot, DV_velmax, DV_velmax_start);
                fprintf(f1o,'%f\t%f\t%f\t%f\t%f\n',DV_dist, DV_ADavg, DV_AUC, DV_xflp_tot, DV_ang_tot);

                clear DV_total_time DV_latency DV_inmot DV_velmax DV_velmax_start DV_dist DV_ADavg DV_AUC DV_xflp_tot DV_ang_tot
                fclose(fid);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               %% SAVE SAVE INTERPOLATED X,Y TRAJECTORIES FOR PRODUCING FIGURES
%               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                try

                    %%// interpolated
                    % have repeating values: need to run consolidator function! 
                    it = (t-t(1)); % takes starts t off at zero
                    it = it/it(length(it)); % normalize the it vector (between 0 and 1) 
                    [itx,newx] = consolidator(it,x,@mean); % removes duplicates within, should just replace with mean. argh. 
                    ix = interp1(itx,newx,0:.02:1); % make x the same length for all participants, 51 time points
                    [ity,newy] = consolidator(it,y,@mean);
                    iy = interp1(ity,newy,0:.02:1);
                    trajAngInt = 90-(atan2d(iy+.0001,ix));
                    for i=1:51,
                        fprintf(f3o,'%d\t%d\t%s\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%f\t%f\t%f\t%f\n',mm,subjnum,cell2mat(tc{4}(1)),trial,cell2mat(tc{5}(1)),cell2mat(tc{6}(1)),cell2mat(tc{7}(1)),cell2mat(tc{8}(1)),cell2mat(tc{9}(1)),cell2mat(tc{10}(1)),cell2mat(tc{11}(1)),cell2mat(tc{12}(1)),cell2mat(tc{13}(1)),cell2mat(tc{14}(1)),cell2mat(tc{15}(1)),i,ix(1,i),iy(1,i),trajAngInt(1,i));
                    end

                catch
                    display('problem with saving trajectories')
                end 
                                
            end    
        end
    end
end

fclose(f1o);
fclose(f3o);




