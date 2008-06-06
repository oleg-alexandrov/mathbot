function main ()

%prepare the screen
figure(1); clf; hold on; axis equal; axis off;

% points to graph 
P=[-12, 0]; Q=[0, 0]; R=[32, 0]; S=[0, 24];

% text fontsize, line thickness, distance from text to graphics
fs=30; thick=3; dist=fs*0.1; 

or=1; % to which side of a given segment the text should go

% draw the segments
side(P, Q, or, thick, dist, fs, 'b')
side(Q, R, or, thick, dist, fs, 'd')
side(R, S, or, thick, dist, fs, 'e')
side(S, P, or, thick, dist, fs, 'c')
side(S, Q, -or, thick, dist, fs, 'a')

% save as eps. 
saveas(gcf, 'Heronian_trig.eps', 'psc2');

% Use later the command
% convert -antialias -density 400x400 -scale 10% Heronian_trig.eps Heronian_trig.png
% to convert to PNG. This keeps small size but good detail.

% a function to draw a segment and put some text a bit to a side of it.
function side(P, Q, or, thick, dist, fs, name)

 plot([P(1) Q(1)], [P(2), Q(2)], 'linewidth', thick);

 v=[(Q(2)-P(2)), -(Q(1)-P(1))]; % PQ rotated by 90 deg clockwise
 
 if or < 0 
  v=-v; % change orientation
 end
 
 R=(P+Q)/2+dist*v/max(abs(v)); 
 H=text(R(1), R(2), name);
 set(H, 'fontsize', fs, 'VerticalAlignment', 'c', 'HorizontalAlignment', 'c')
