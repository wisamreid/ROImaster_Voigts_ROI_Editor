%% ROImaster
%
% quick and dirty ROI editor for neural imaging data
% distributed as is
%
% left mouse: start Xcorr seed
% right mouse: back to image
% L: label selected group
% space: add new ROI to current group
% F: display mean
% D:display std
% Q: quit
% X: delete ROIs from current group
%
%
% 2013 jvoigts@mit.edu


%% read subset of stack

readInDirectory='/media/New Volume/2p/NT_2P4/TSeries-07302013-1301-006/registered/';
%expects pngs

files = dir([readInDirectory '*.png']);
numImages=numel(files)

stack= [];
c=0;
ff=fspecial('gaussian',11,0.5);
for i=1:1500;%numImages
    c=c+1;
    disp(i);
    
    %fnum=ceil(rand*(numImages-1));
    fnum=i;
    
    %fnum=i;
    I=imread([readInDirectory 'registered_' num2str(fnum),'.png']);
    %  I=I(:,1:100);
    I=conv2(double(I),ff,'same');
    %imagesc(I);
    %drawnow;
    
    
    stack(:,:,i)=I;
    
    % ts(i)=mean(mean(I(370:376,272:287)));
end

%% reset ROIS

Rois=[];
Rois.date_started=date;
Rois.data_dir=readInDirectory;
Rois.N=0;
Rois.masks=[];  % binary masks
Rois.groups=[]; % int id per mask, assigning to groups
Rois.grouplabels=[]; %laber per roi, not per group
Rois.outlines=[] % mostly just for plotting

%% run ROImaster
figure(1);
run=1;
displayxc=0;
plotstd=1;
set(gca, 'position', [0.02 0.04 1 .94]);

selected_group=1;
updatexc=0;

Ngroups=60*3;
UIheight=500;

stdim=(std(single(stack),[],3));
meanim=mean(stack,3);

for i=1:Ngroups
    roiUIpos(end-i+1,1)=-30*ceil(i/60);
    roiUIpos(end-i+1,2)=2+(rem(i-1,60)/60)*UIheight;
end;

while run
    clf; hold on;
    % plot UI
    for i=1:Ngroups
        ningroup=sum(Rois.groups==i);
        if (i==selected_group)
            text(roiUIpos(i,1),roiUIpos(i,2),[num2str(i) ,'-',num2str(ningroup)],'BackgroundColor',[.3 .8 1]);
            try
                text(-60,505,Rois.grouplabels{i},'color',[1 0 0]);
            end;
        else
            text(roiUIpos(i,1),roiUIpos(i,2),[num2str(i) ,'-',num2str(ningroup)]);
              try
                if numel(Rois.grouplabels{i})>0
                       text(roiUIpos(i,1),roiUIpos(i,2),[num2str(i) ,'-',num2str(ningroup)],'BackgroundColor',[.7 .7 .7]);
            
                end;
            end;
            
        end;
    end;
    
    
    
    
    
    if displayxc
        
        
        if 0
            if  updatexc
                % 2 step refinement
                ref= (squeeze( stack(ceil(y),ceil(x),:) ));
                %ref=(mean(squeeze(mean(stack(ceil(y+[-1:1]),ceil(x+[-1:1]),:),1) ),1))';
                xc=I.*0;
                for i=1:2:size(stack,1) % first subsample every 2nd
                    for j=1:2:size(stack,2)
                        c=corrcoef(squeeze(stack(i,j,:)),ref);
                        xc(i,j)=c(1,2);
                    end
                end;
                imagesc(xc); daspect([1 1 1]); drawnow;
                for fillin=find(xc(:)>.1)' % fill in where we detected any corr >.1
                    [a,b]=ind2sub(size(I),fillin);
                    for i=[-1 0 1]+a
                        for j=[-1 0 1]+b
                            if (i>0) && (j>0) && (i<size(I,1))&& (j<size(I,2)) && ~(i==a && j==b)
                                c=corrcoef(squeeze(stack(i,j,:)),ref);
                                xc(i,j)=c(2,1);
                            end;
                        end
                    end;
                    
                end;
                xc(ceil(y),ceil(x))=0;
            end;
            imagesc(xc); daspect([1 1 1]);
            
        else
            %iterative region growing
            if  updatexc
                ref= (squeeze( stack(ceil(y),ceil(x),:) ));
                xc=I.*0;
                
                xc(ceil(y),ceil(x))=0.11; % seed
                
                it=1;
                while it<50
                    sig=find(xc>0.04);
                    mask=I.*0; mask(sig)=1;
                    mask=conv2(mask,ones(5),'same')>0;
                    update=find((xc==0).*(mask==1));
                    if numel(update)<1
                        it=500;
                    end;
                    for fillin=update' % fill in where we detected any corr >.1s
                        [a,b]=ind2sub(size(I),fillin);
                        c=corrcoef(squeeze(stack(a,b,:)),ref);
                        xc(a,b)=c(2,1);
                    end;
                    %imagesc(xc);
                    %  image((1-mask).*I./10+ ((xc*200)))
                    % daspect([1 1 1]);drawnow;
                    it=it+1;
                    
                end;
            end;
            
        end
        if updatexc
            xc(ceil(y),ceil(x))=0;
        end;
        image((1-mask).*I./10+ ((xc*200)))
        daspect([1 1 1]);
    else
        if plotstd
            I=stdim;
        else
            I=meanim;
        end;
        imagesc(I); daspect([1 1 1]);
        if plotstd
            xlabel('plotting std');
        else
            xlabel('plotting mean');
        end;
    end;
    
    %plot outlines
    for i=1:Rois.N
        if (selected_group==Rois.groups(i))
         plot(Rois.outlines{i}([1:end,1],1),Rois.outlines{i}([1:end,1],2),'color',[1 1 1].*1);
        else
            plot(Rois.outlines{i}([1:end,1],1),Rois.outlines{i}([1:end,1],2),'color',[1 1 1].*.5);
        end;
        text(mean(Rois.outlines{i}(:,1)),mean(Rois.outlines{i}(:,2)),num2str(Rois.groups(i)),'color',[1 1 1].*.6);
    end;
    
    %plot example data trace
    sel=find(selected_group==Rois.groups);
    tr=[];
    for i=1:numel(sel);
        xa=round(min(Rois.outlines{sel(i)}(:,1)));
        xb=round(max(Rois.outlines{sel(i)}(:,1)));
        ya=round(min(Rois.outlines{sel(i)}(:,2)));
        yb=round(max(Rois.outlines{sel(i)}(:,2)));
        
        for t=1:size(stack,3)
            tr(i,t)=mean(mean(stack(ya:yb,xa:xb,t).*Rois.masks{sel(i)}(ya:yb,xa:xb)));
        end;
    end;
    plot((tr'.*5)-200, repmat( [1:size(stack,3)],numel(sel),1)' );
    
    
    xlim([-200 size(stack,2)]);
    ylim([0 size(stack,1)]);
    set(gca, 'position', [0 0 1 1]);
    
    
    [x,y,b]=ginput(1)
    
    if b==108 %l
        
        prompt = {'Enter new label:'};
        dlg_title = 'new group label';
        num_lines = 1;
        def = {''};
        newlabel = inputdlg(prompt,dlg_title,num_lines,def);
        
        Rois.grouplabels{selected_group}=newlabel;
        
    end;
    
    if b==120 %x
        %delete current group
        
        
    end;
    
    if b==100 %d
        plotstd=1;
    end;
    if b==102  %f
        plotstd=0;
    end;
    if b==1; %left mouse
        if x>0
            displayxc=1;
            updatexc=1;
        else
            [~,selected_group]=min(((x-10)- roiUIpos(:,1)).^2 + (y- roiUIpos(:,2)).^2);
            updatexc=0;
        end;
    end;
    if b==3; %right mouse
        displayxc=0;
    end;
    if b==113 % q
        disp('exited')
        run=0;
    end;
    
    if b==32 %space
        t= imfreehand(gca,'Closed' ,1);
        t.setClosed(1);
        mask=t.createMask;
        %  imagesc(mask);
        %xlim([-100 size(stack,2)]);
        % ylim([0 size(stack,1)]);
        % set(gca, 'position', [0 0 1 1]);
        % drawnow;
        displayxc=0;
        
        Rois.N=Rois.N+1;
        
        Rois.masks{Rois.N}=logical(mask);
        Rois.groups(Rois.N)=selected_group;
        Rois.outlines{Rois.N}=t.getPosition;
        Rois.labels{Rois.N}='';
        
    end;
    title(readInDirectory);
end;

%% Get F(roi) and F(neuropil) from an imagestack on disk.
tic
n=1;
aa=[];
%neuropilScale=0.7;
for i=1:numImages
    
    if (rem(i,100)==0)
        fprintf('%d/%d (%d%%)\n',i,numImages,round(100*(i./numImages)));
    end;
    
    imageToMeasure=uint16(imread([readInDirectory 'registered_' int2str(i)],'png'));
    
   
    for j=1:Rois.N
        xa=round(min(Rois.outlines{j}(:,1)));
        xb=round(max(Rois.outlines{j}(:,1)));
        ya=round(min(Rois.outlines{j}(:,2)));
        yb=round(max(Rois.outlines{j}(:,2)));

       roiValues(i,j)=mean(mean(imageToMeasure(ya:yb,xa:xb).*uint16(Rois.masks{j}(ya:yb,xa:xb))));
    end;
    
end
toc