%   NOTA : Prima di eseguire i codice è preferibile attivare il parallel pool
%          tramite il comando parpool nella Command Window;

%   Script principale per l'esecuzione dell'algoritmo: Multiple Component
%   Matching per la Re-identificazione di persone a breve termine.

%   Carico il dataset VIPeR e le relative maschere;
load('aleMasks_VIPeR.mat');
load('vecImage.mat');


parameters = Params();
descriptorBuilder = DescriptorBuilder();
 
disp('Sto costruendo i descriptor');

%   La variabile msk corrisponde alla maschere 
%   caricate con load('aleMasks_VIPeR.mat');
descriptors = cell(1,size(msk,2));
 
 parfor i = 1 : size(msk,2)
    
    %   Serve nel caso si voglia utilizzare il metodo 
    %   non implementato CreateSimulatedPatches.
    generateSimulatedPatches = 0 ; 
     
    disp(strcat('Sto creando il descriptor # ', num2str(i)));
    
    %   La variabile vecImage corrisponde alle immagini del VIPeR dataset 
    %   caricato con  load('vecImage.mat');
    descriptors{i}  =   descriptorBuilder.BuildDescriptor( vecImage{i}, msk{i}, generateSimulatedPatches);  
     
 end

lenghtTemplate  =   cast(size(msk,2)/2, 'int32' );

templateSet     =   cell(1,lenghtTemplate);
probeSet        =   cell(1,lenghtTemplate);
index   =   1;

%   Divido i descriptor in ProbeSet e TemplateSet.
for i = 2 :2: size(msk,2)
    
    templateSet{index} =    descriptors{i-1};
    probeSet{index}  =    descriptors{i};
    index   =   index+1;
    
end


scores      =   zeros(size(probeSet,2) ,size(probeSet,2));

disp('Matching');
matcher     =   DescriptorMatcher(); 

for i = 1 : size(probeSet,2) 
    
    disp(strcat('Matching probe #', num2str(i)));    
    temp    = templateSet{i}; 
    
    parfor j = 1 : size(templateSet,2)

        scores(i,j) =   matcher.Match(temp,probeSet{j});
                       
    end
        
end

[ MatchOrder , ProbeOrder ] = sort(scores,2);    

disp('Sto calcolcando la curva CMC');
cmc     =   ComputeCMC(ProbeOrder);

% disp('Sto salvando le variabili: cmc; scores; MatchOrder; ProbeOrder; descriptors. ')    
% save('Test','cmc','scores','MatchOrder','ProbeOrder','descriptors');

disp('Sto graficando la curva CMC');

t = 1: 1 : size(cmc,2);
y = cmc*100;

plot(t,y)
xlabel('Rank score')
ylabel('Recognition percentage')
title('CMC Curve')
axis([0 size(cmc,2) , 0 105])








