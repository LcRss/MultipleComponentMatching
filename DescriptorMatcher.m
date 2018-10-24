%   La classe DescriptorMatcherTest definisce la metrica per misurare la
%   distanza tra due variabili descriptor.

classdef DescriptorMatcher < handle
    
    properties
        
        parameters  =   Params();
        
    end
    
    methods 
        
        %   Riceve in ingresso due descriptor e ne calcola la "distanza".
        function output = Match(obj, inputTemplate, inputProbe)
            
            d   =   0;
            templatesNr     =   0;
            
            TemplateBags    = inputTemplate.Bags;
            ProbeBags       = inputProbe.Bags;
            
            %   Calcola la distanza tra le bag dei due descriptor.
            for i = 1 : size( inputTemplate.Bags, 2)
               
               tempBagSize     =   inputTemplate.Bags{i}.Size;
               probBagSize     =   inputProbe.Bags{i}.Size;
               if tempBagSize~=0 && probBagSize~=0
                   
                   templatesNr  =   templatesNr + 1;
                   d   =   d + obj.matchBag( TemplateBags{1,i}, ProbeBags{1,i});
                    
               end    
                
            end
            
            output  =   d / templatesNr;
            
        end
        
        %   Riceve in ingresso bag e ne calcola la "distanza".
        function output = matchBag( obj, inputTemplateBag, inputProbeBag)
            
            %   Il metodo Size della classe Bag ritorna il numero di Patch.
            height  =   inputProbeBag.Size;
            width   =   inputTemplateBag.Size;
            
            distances   =   zeros(height, width); 
            
            TemplatePatches = inputTemplateBag.Patches;
            ProbePatches    = inputProbeBag.Patches;
            
            %   Calcola le Bhattacharyya distances tra la patch p della bag
            %   del probe e ogni patch della bag del template.
            for p = 1 : inputProbeBag.Size
            
                feature0 = ProbePatches{1,p}.features;
                
                %   Creo una matrice sulle cui righe è ripetuto il vettore
                %   feature0, tante volte quante sono le patch nel
                %   templateBag.
                matFeature0 = repmat(feature0, inputTemplateBag.Size, 1);
                
                matFeaturesTemplate = zeros(inputTemplateBag.Size , size(feature0 , 2));
                
                %   Creo una matrice le cui righe sono i vettori feature 
                %   delle patch presenti nel templateBag.
                for t = 1 : inputTemplateBag.Size
                  
                    matFeaturesTemplate(t, 1:end) = TemplatePatches{1,t}.features;
                    
                end   
                
                %   Il codice commentato che segue ha lo scopo di porre a
                %   zero i valori delle matrici matFeature0 e 
                %   matFeaturesTemplate che non contribuiscono al calcolo
                %   delle Bhattacharyya distances, permettendo di osservare
                %   i valori utili. Al fine del programma non è comunque
                %   rilevante.
                
                %   Creo due matrici di booleani 
                %   Questa matrice avrà il valore True nelle posizioni in cui
                %   la matrice matFeature0 ha il valore 0 
                
                %   logicMatFeature0 = ( matFeature0 == 0 );
                
                %   Questa matrice avrà il valore True nelle posizioni in cui
                %   la matrice matFeaturesTemplete ha il valore 0
                
                %   logicMatFeaturesTemplate = ( matFeaturesTemplate == 0 );
                
                %   Applicando la funzione or alle due matrici ottengo una
                %   matrice in cui i valori True corrispondono alle posizioni
                %   in cui almeno una delle due matrici (matFeature0,
                %   matFeaturesTemplate) ha un valore 0.
                
                %   ZeroPosition = or(logicMatFeature0, logicMatFeaturesTemplate);
                
                %   Pongo a 0, in entrambe le matrici, le posizioni in cui
                %   almeno una delle due ha gia un valore 0.
                
                %   matFeature0(ZeroPosition) = 0;
                %   matFeaturesTemplate(ZeroPosition) = 0;
                
                matBh = matFeature0 .* matFeaturesTemplate; 
                matBh = sqrt(matBh);
                matBh = sum(matBh,2);
                
                %   Creo un vettore di booleani, dove i valori True
                %   corrispondo alle posizioni con i valori >1. 
                overOne = matBh > 1;
                
                %   Pongo a 1 tutti i valori > 1.
                matBh(overOne) = 1;
                
                matBh = sqrt(1-matBh);
                
                %   Copio sulla riga p-esima della matrice distances i
                %   valori del vettore matBh calcolato.
                distances(p, 1:inputTemplateBag.Size)= matBh;

            end
            
            %   La matrice distances calcolata contiene alla posizione (i,j)
            %   la Bhattacharyya distanza tra la patch i e la patch j.
            %   Con i del Probe e j del Template.
            
            %   Hausdorff distance.
            %   max(h(X,Y),h(Y,X))
            %   h(X,Y) = max min || x-y||
            
            %   Calcolo i valori minimi per riga della matrice distances.
            %   Equivale a calcolare la distanza minima tra ogni patch i 
            %   del probe e le patch del template.
            distances1  =   min( distances,[],2 );
            distances1  =   sort(distances1);
            
            %   Calcolo i valori minimi per colonna della matrice distances.
            %   Equivale a calcolare la distanza minima tra ogni patch i 
            %   del template e le patch del probe.
            distances2  =   min(distances);        
            distances2  =   sort(distances2);
            
            %   Parametro fissato dagli autori.
            k1  =   obj.parameters.DescMatching_kValue;
            k2  =   k1;

            if k1 > size(distances1,1)
                k1  =   size(distances1,1)-1;
            end

            if k2 > size(distances2,2)
                k2  =   size(distances2,2)-1;
            end
            
            %   Calcolo la k-th Hausdorff distance.
            %       h(X,Y) = k-th min || x-y||    
            output  =   max(distances1(k1),distances2(k2));    

       end
    end    
end

