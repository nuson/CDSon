% DSSon_Basic_Model.m
%
%   Direct Segmented Sonification
%   for FRED-Data
%
%   Basic Model
%
%   by Paul Vickers and Robert H�ldrich
%   -----------------------------------
%
%   segments are determined by the crossing points between the FRED signal
%   and the individual slowly time-varying target (weighted mean of nominal target,
%   i.e.0.4 Hz, and slowly varying indiviual mean)
%
%   kappa=5;
%
%   DELTA=5; no overlapping sonic events
%
%   amplitude modulator: |x_i|, i.e. PHI_ring=1
%
%   alpha=2, beta=2
%
%   timbre: pure sine tones

clear all
close all

% plot figures? Yes: plot_flag=1, No: plot_flag=0
plot_flag=1;

% samping rate in Hz of output file
fs=44100;

% time compression factor "kappa"
% i.e. duration of sonification divided by duration of data
kappa=5;

for sound=1:3
    sound
    switch sound
        case 1
            wav_name='DSSon_Basic_A_e.wav';
            %dd=wavread('DA2.wav'); % MATLAB 2011 syntax
            dd=audioread('DA2.wav');
            fs_data=100;
            d=resample(dd,fs,fs_data*kappa)*2; %the factor of 2 is due to our coding of the frequency values in the wav-file
        case 2
            wav_name='DSSon_Basic_B.wav';
            %dd=wavread('DB1.wav'); & MATLAB 2011 syntax
            dd=audioread('DB1.wav');
            fs_data=100;
            d=resample(dd,fs,fs_data*kappa)*2; %the factor of 2 is due to our coding of the frequency values in the wav-file
        case 3
            wav_name='DSSon_Basic_A_n.wav';
            %dd=wavread('DA1.wav'); % MATLAB 2011 syntax
            dd=audioread('DA1.wav');
            fs_data=100;
            d=resample(dd,fs,fs_data*kappa)*2; %the factor of 2 is due to our coding of the frequency values in the wav-file
    end
    
    % low-pass filter to calculate the slowly varying indiviual mean
    mean_d=filtfilt(0.0001,[1 -0.9999],d);
    target_d=0.4;
    
    %individual slowly time-varying target: weighted mean of nominal target,
    %i.e.0.4 Hz, and slowly varying indiviual mean
    t_d=0.2*target_d+0.8*mean_d;
    
    % plot data values and trend signal
    if plot_flag
        lt=60;
        ttt=1:length(d);
        ttt=ttt/fs*kappa;
        % Create figure
        width=660;
        height=350;
        x0=300;
        y0=300;
        figure1 = figure('Units','pixels',...
            'Position',[x0 y0 width height],...
            'PaperPositionMode','auto');
        axes1 = axes('Parent',figure1,...
            'FontUnits','points',...
            'FontWeight','normal',...
            'YTickLabel',{'0.0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1.0'},...
            'YTick',[0 0.1 0.2 0.3 0.4 0.5 0.6 0.7],...
            'XTick',[0 5 10 15 20 25 30 35 40 45 50 55 60],...
            'Units','pixels',...
            'Position',[52 42 600 300],...
            'FontSize',14,...
            'FontName','Times','LineWidth',1.5);
        %% Uncomment the following line to preserve the X-limits of the axes
        % xlim(axes1,[0 60]);
        %% Uncomment the following line to preserve the Y-limits of the axes
        % ylim(axes1,[0.1 0.7]);
        box(axes1,'on');
        grid(axes1,'on');
        hold(axes1,'all');
        
        % Create multiple lines using matrix input to plot
        % plot1 = plot(X1,YMatrix1,'Parent',axes1,'Color',[0 0 0]);
        % set(plot1(1),'LineWidth',1,'DisplayName','data');
        % set(plot1(2),'LineWidth',3,'LineStyle','--','DisplayName','trend');
        plot(ttt,d,'k','LineWidth',1.4,'DisplayName',' data');
        plot(ttt,t_d,'k--','LineWidth',3,'DisplayName',' trend');
        axis([0 lt 0.1 0.7]);
        
        % Create xlabel
        % set(gca,'layer','top');
        xlabel('Time (s)','FontSize',16,'FontName','Times','Position',[30 0.06] );
        %       xlabel('seconds','FontSize',18,'FontName','Times', 'interpreter','latex');
        % Create ylabel
        ylabel('Revolution rate (Hz)','FontSize',16,'FontName','Times','Position',[-2.6 0.4] );%'Position',[10 15 ] );
        
        % Create legend
        legend1 = legend(axes1,'show');
        set(legend1,'Units','pixels','FontSize',16);
    end
    
    
    % determination of the cutting points
    d_ex_mean=d-t_d;
    int_points=find(d_ex_mean(1:end-1).*d_ex_mean(2:end)<0);
    int_points=[0;int_points;length(d_ex_mean)];
    l_seg=length(int_points)-1;
    if d_ex_mean(1)>0
        n_pos=floor((l_seg+1)/2);
        n_neg=l_seg-n_pos;
        pos_segments=zeros(n_pos,2);
        for ii=1:n_pos
            pos_segments(ii,1)=int_points(ii*2-1)+1;
            pos_segments(ii,2)=int_points(ii*2);
        end
        neg_segments=zeros(n_neg,2);
        for ii=1:n_neg
            neg_segments(ii,1)=int_points(2*ii)+1;
            neg_segments(ii,2)=int_points(2*ii+1);
        end
    else
        n_neg=floor((l_seg+1)/2);
        n_pos=l_seg-n_neg;
        neg_segments=zeros(n_neg,2);
        for ii=1:n_neg
            neg_segments(ii,1)=int_points(ii*2-1)+1;
            neg_segments(ii,2)=int_points(ii*2);
        end
        pos_segments=zeros(n_pos,2);
        for ii=1:n_pos
            pos_segments(ii,1)=int_points(2*ii)+1;
            pos_segments(ii,2)=int_points(2*ii+1);
        end
    end
    % END Determination of cutting points
    
    out_file=zeros(length(d_ex_mean)+10000,1);
    
    % to determine DELTA=stretch_d/strech_u*kappa
    stretch_u=1;
    stretch_d=1;
    
    %reference frequencies
    f_ref_pos=400;
    f_ref_neg=300;
    
    % alpha und beta, the transposition parameters
    % I skipped the old parameter c_alpha_beta and adjusted alpha and beta
    % accordingly.
    alpha=2;
    beta=2;
    
    % power law distortion factor PHI_ring
    PHI_ring=1.;
    
    for ii=1:n_pos
        x=resample(d_ex_mean( pos_segments(ii,1):pos_segments(ii,2)),stretch_u,stretch_d);
        % to cure dimensionality nonsense
        if pos_segments(ii,1)==pos_segments(ii,2)
            x=x';
        end
        f_i=f_ref_pos*2.^(alpha*t_d(pos_segments(ii,1)))*2.^(beta*x);
        cum_phi=cumsum(2*pi*f_i/fs);
        x_sound=abs(x).^PHI_ring.*sin(cum_phi);
        out_file(pos_segments(ii,1):pos_segments(ii,1)+length(x_sound)-1)=out_file(pos_segments(ii,1):pos_segments(ii,1)+length(x_sound)-1)+x_sound;
    end
    for ii=1:n_neg
        x=resample(d_ex_mean( neg_segments(ii,1):neg_segments(ii,2)),stretch_u,stretch_d);
        % to cure dimensionality nonsense
        if neg_segments(ii,1)==neg_segments(ii,2)
            x=x';
        end
        f_i=f_ref_neg*2.^(alpha*t_d(neg_segments(ii,1)))*2.^(beta*x);
        cum_phi=cumsum(2*pi*f_i/fs);
        x_sound=abs(x).^PHI_ring.*sin(cum_phi);
        out_file(neg_segments(ii,1):neg_segments(ii,1)+length(x_sound)-1)=out_file(neg_segments(ii,1):neg_segments(ii,1)+length(x_sound)-1)+x_sound;
    end
    % wavwrite(0.7*out_file,fs,16,wav_name); % MATLAB 2011 syntax
    audiowrite(wav_name, 0.7*out_file, fs);
    
    % plot spectrogram
    if plot_flag
        wind=hanning(4096);
        [S,F,TT,P] = spectrogram(out_file, wind,length(wind)-256,8092,fs);
        width=1320;
        height=700;
        x0=100;
        y0=100;
        figure2 = figure('Units','pixels',...
            'Position',[x0 y0 width height],...
            'PaperPositionMode','auto','InvertHardcopy','on',...
            'Colormap',[1 1 1;0.98412698507309 0.98412698507309 0.98412698507309;0.968253970146179 0.968253970146179 0.968253970146179;0.952380955219269 0.952380955219269 0.952380955219269;0.936507940292358 0.936507940292358 0.936507940292358;0.920634925365448 0.920634925365448 0.920634925365448;0.904761910438538 0.904761910438538 0.904761910438538;0.888888895511627 0.888888895511627 0.888888895511627;0.873015880584717 0.873015880584717 0.873015880584717;0.857142865657806 0.857142865657806 0.857142865657806;0.841269850730896 0.841269850730896 0.841269850730896;0.825396835803986 0.825396835803986 0.825396835803986;0.809523820877075 0.809523820877075 0.809523820877075;0.793650805950165 0.793650805950165 0.793650805950165;0.777777791023254 0.777777791023254 0.777777791023254;0.761904776096344 0.761904776096344 0.761904776096344;0.746031761169434 0.746031761169434 0.746031761169434;0.730158746242523 0.730158746242523 0.730158746242523;0.714285731315613 0.714285731315613 0.714285731315613;0.698412716388702 0.698412716388702 0.698412716388702;0.682539701461792 0.682539701461792 0.682539701461792;0.666666686534882 0.666666686534882 0.666666686534882;0.650793671607971 0.650793671607971 0.650793671607971;0.634920656681061 0.634920656681061 0.634920656681061;0.61904764175415 0.61904764175415 0.61904764175415;0.60317462682724 0.60317462682724 0.60317462682724;0.58730161190033 0.58730161190033 0.58730161190033;0.571428596973419 0.571428596973419 0.571428596973419;0.555555582046509 0.555555582046509 0.555555582046509;0.539682567119598 0.539682567119598 0.539682567119598;0.523809552192688 0.523809552192688 0.523809552192688;0.507936537265778 0.507936537265778 0.507936537265778;0.492063492536545 0.492063492536545 0.492063492536545;0.476190477609634 0.476190477609634 0.476190477609634;0.460317462682724 0.460317462682724 0.460317462682724;0.444444447755814 0.444444447755814 0.444444447755814;0.428571432828903 0.428571432828903 0.428571432828903;0.412698417901993 0.412698417901993 0.412698417901993;0.396825402975082 0.396825402975082 0.396825402975082;0.380952388048172 0.380952388048172 0.380952388048172;0.365079373121262 0.365079373121262 0.365079373121262;0.349206358194351 0.349206358194351 0.349206358194351;0.333333343267441 0.333333343267441 0.333333343267441;0.31746032834053 0.31746032834053 0.31746032834053;0.30158731341362 0.30158731341362 0.30158731341362;0.28571429848671 0.28571429848671 0.28571429848671;0.269841283559799 0.269841283559799 0.269841283559799;0.253968268632889 0.253968268632889 0.253968268632889;0.238095238804817 0.238095238804817 0.238095238804817;0.222222223877907 0.222222223877907 0.222222223877907;0.206349208950996 0.206349208950996 0.206349208950996;0.190476194024086 0.190476194024086 0.190476194024086;0.174603179097176 0.174603179097176 0.174603179097176;0.158730164170265 0.158730164170265 0.158730164170265;0.142857149243355 0.142857149243355 0.142857149243355;0.126984134316444 0.126984134316444 0.126984134316444;0.111111111938953 0.111111111938953 0.111111111938953;0.095238097012043 0.095238097012043 0.095238097012043;0.0793650820851326 0.0793650820851326 0.0793650820851326;0.0634920671582222 0.0634920671582222 0.0634920671582222;0.0476190485060215 0.0476190485060215 0.0476190485060215;0.0317460335791111 0.0317460335791111 0.0317460335791111;0.0158730167895556 0.0158730167895556 0.0158730167895556;0 0 0],...
            'Color',[1 1 1]);
        % Create axes
        
        axes1 = axes('Parent',figure2,...
            'YTickLabel',{'50Hz','100Hz','200Hz','400Hz','800Hz','1.6kHz','3.2kHz','6.4kHz'},...
            'YTick',[50 100 200 400 800 1600 3200 6400],...
            'YScale','log',...
            'YMinorTick','on',...
            'YMinorGrid','off',...
            'FontUnits','points',...
            'FontWeight','normal',...
            'XTickLabel',{'0','2','4','6','8','10','12', '30 sec', '35 sec'},...
            'XTick',0:2:60,...
            'XMinorTick','on',...
            'Units','pixels',...
            'Position',[110 72 1192 610],...
            'FontSize',28,...
            'FontName','Times','LineWidth',3,...
            'GridLineStyle','- -',...
            'CLim',[-80 -30]);
        ylim(axes1,[300 1100]);
        xlim(axes1,[0 12]);
        
        %'YTickLabel',{'200Hz','300Hz','400Hz','600Hz','800Hz','1.2kHz','1.6kHz','3.2kHz', '6.4kHz'},...
        %'YTick',[ 200 300 400 600 800 1200 1600 3200 6400],...
        %% Uncomment the following line to preserve the X-limits of the axes
        xlabel('Time (s)','FontSize',28,'Position',[6 275]);
        set(gca,'layer','top');
        for ii=0:1
            line([0;12],[400*2^ii;400*2^ii],'LineWidth',0.5,'LineStyle','- -','Color',0*[1 1 1]);
            %line([0;4],[400+200*ii;400+200*ii],'LineWidth',0.5,'LineStyle','- -','Color',0*[1 1 1]);
        end
        for ii=2:2:10
            line([ii;ii],[100;3200],'LineWidth',0.5,'LineStyle','- -','Color',0*[1 1 1]);
        end
        box(axes1,'on');
        grid(axes1,'off');
        hold(axes1,'all');
        
        % Create surf
        %subplot(1,2,2)
        %subplot('Parent',axes1)
        surf(TT,F,10*log10(P),'Parent',axes1,'EdgeColor','none');
    end
end

