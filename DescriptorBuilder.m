%   La classe DescriptorBuilder creare la variabile descriptor per 
%   per un'immagine.

classdef DescriptorBuilder < handle
       
    properties
        parameters          ;
        tmpBGR              ;
        tmpHSV              ; 
        hsvConversionCache  ; 
        random              ;         
    end
    
    methods
        
        function obj = DescriptorBuilder()
        
            obj.parameters  =    Params();
            obj.random      =    randi([0, 12345]);     
        
        end
        
        function output_Descriptor = BuildDescriptor( obj, inputBGRframe,...
                inputMask, doSimulation)
            
            %   Queste tre variabili sono utilizzate dal metodo non
            %   implementato CreateSimulatedPatches.
            obj.tmpBGR  =   zeros( size(inputBGRframe,1), size(inputBGRframe,2), 3);     
            obj.tmpHSV  =   zeros( size(inputBGRframe,1), size(inputBGRframe,2), 3);     
            obj.hsvConversionCache  =   containers.Map('KeyType','double','ValueType','any');    
            %
            
            %   Converto l'immagine in BGR per adeguarmi ad OpenCV.
            inputBGRframe           =   cv.cvtColor(inputBGRframe,'RGB2BGR'); 
            
              
            %   Aumento il contrasto dell'immagine.
            contrastValue           =   1.2 ;
            BGRframe_contrasted     =   obj.Contrast( inputBGRframe, contrastValue);
            
            %   Converto l'immagine in HSV.
            HSVframe    =   cv.cvtColor( inputBGRframe,'BGR2HSV');
            
            %   Converto l'immagine BGR con il contrasto aumentato in HSV.            
            HSVframe_contrasted     =   cv.cvtColor( BGRframe_contrasted,'BGR2HSV');     
            
            %   Calcolo l'asse che separa il torso dalle gambe.
            y_TL    =   obj.ComputeTorsoLegsAxis( HSVframe, inputMask);
            
            %   Calcolo l'asse che separa il torso dalla testa.
            y_HT    =   obj.ComputeHeadTorsoAxis( inputMask, y_TL);
                        
            descriptor = Descriptor();
            
            difference = cast( y_TL - y_HT,'int32'); 
            
            %   Creo la bag contenente le patch nella reagione y_TL - y_HT,
            %   il torso.
            descriptor.Bags{1} = obj.CreateBag_Color( BGRframe_contrasted,...
                HSVframe_contrasted, inputMask, doSimulation, y_HT, difference);   %1   
            
            %   Creo la bag delle gambe.
            descriptor.Bags{2} = obj.CreateBag_Color( BGRframe_contrasted,...
                HSVframe_contrasted, inputMask, doSimulation, y_TL, size(inputBGRframe,1) - y_TL); %0    
                    
            output_Descriptor   =   descriptor;
        
        end    
        
        function output = CreateBag_Color( obj, inputBGRframe, inputHSVframe,...
                inputMask, doSimulation, inputY1, inputHeight)
        
            bag     =   Bag();
            BGRframe_width  =   size(inputBGRframe,2);
            %   Regione dell'immagine considerata dalla bag.
            bag.Rectangle   =   [ 1 inputY1 BGRframe_width inputHeight ];
            
            
            %   Numero di patch creata.
            count   =   1;
            %   Indice della variabile cell{} Patches di bag.
            index   =   1;
            %   Per ogni bag creo al massimo 80 patch. Possono essere meno di
            %   80 perchè considero solo le patch che possiedono una valore
            %   sufficiente di pixel dell'individuo dell'immagine.
            while count < obj.parameters.DescCreation_ColourPatchNr+1 
                
                HSVframe_width  =   size(inputHSVframe,2);
                
                stripWidth      =   obj.parameters.DescCreation_PatchWidth * HSVframe_width;
                
                inputHeight     =   cast(inputHeight,'double');                   
                stripHeight     =   obj.parameters.DescCreation_PatchHeight * inputHeight;
                            
                first_interval  =   [ 1 cast(HSVframe_width-stripWidth,'int32') ];
                second_interval =   [ inputY1 cast(inputY1+inputHeight-stripHeight,'int32') ];
                
                %   Creo le coordinate della posizione della patch
                %   nell'immagine.
                x   =   randi( first_interval, 1, 1);
                y   =   randi( second_interval, 1, 1);
             
                stripWidth_castInt  = cast(floor(stripWidth),'int32');
                stripHeight_castInt = cast(floor(stripHeight),'int32');
                
                rectangle   =   [ x y stripWidth_castInt stripHeight_castInt ];
                
                %   La variabile doSimulation é true quando si vuole
                %   utilizzare il metodo CreateSimulatedPatch non
                %   implementato.
                if doSimulation
                   
                   %    Incompleto. 
                   simulatedPatches = obj.CreateSimulatedPatch( inputBGRframe,...
                       inputHSVframe, inputMask, rectangle);
                                      
                else
                    
                    %   Creo la patch.
                    tmpPatch    =   obj.CreateRealPatch( inputHSVframe, inputMask, 1, 0, rectangle);
                    if isa(tmpPatch,'Patch')
                        
                        bag.Patches{index} = tmpPatch;
                        index   =   index +1;
                                 
                    end
                    
                end
                count = count +1;
            end
            
            output  =   bag; 
            
        end
        
        %   Medoto non completo.
        function CreateSimulatedPatches(obj, inputBGRframe, inputHSVframe,...
                inputMask, inputRectangle)
            
            % Metodo incompleto.
            X_0         =   inputRectangle(1);
            X_Width     =   inputRectangle(3);
            Y_0         =   inputRectangle(2);
            Y_Height    =   inputRectangle(4);
            
            nonZeroPixels   =   obj.CountNonZeroPixels( inputMask, X_0, X_Width, Y_0, Y_Height);
            
            maskROI_width  =   X_Width;                        
            maskROI_height =   Y_Height;        
            
            area            =   maskROI_height * maskROI_width;
            coverage        =   nonZeroPixels / area;
            
            if  coverage >=  obj.parameters.DescCreation_minPatchCoverage               
                
                BGRframe_ROI    =   inputBGRframe( Y_0:Y_Height, X_0:X_Width, : );
                
                %FIXME     controllare se il metodo mean è opportuno. 
                meanBlue_BGR    =   mean( mean( BGRframe_ROI(:, :, 1) ) );              
                meanGreen_BGR   =   mean( mean( BGRframe_ROI(:, :, 2) ) );
                meanRed_BGR     =   mean( mean( BGRframe_ROI(:, :, 3) ) );
                
                maxValue        =   max( meanBlue_BGR, meanGreen_BGR, meanRed_BGR);
                
                mulFactors      =   obj.parameters.DescCreation_simulVector;
            
                while   maxValue*mulFactors(1) > 240
                    
                    mulFactors = mulFactors - 0.1;
                    
                end
                
                %
                logicVec    =   mulFactors ~= 1;
                num     =   nnz(logicVec);
                var     =   multFactor(logicVec);
                
                logicMask   = inputMask >0;
                
                output  = cell(1,1);
                index   = 1;  
                for i = 1 : num
                    
                    B   =   cast( inputBGRframe( :, :, 1 )*var( i ) ,'int32') ; 
                    G   =   cast( inputBGRframe( :, :, 2 )*var( i ) ,'int32');
                    R   =   cast( inputBGRframe( :, :, 3 )*var( i ) ,'int32');
                    
                    B_logic     =   B >255;
                    G_logic     =   G >255;
                    R_logic     =   R >255;
                                        
                    B_usefull    =   and(logicMask, B_logic);
                    G_usefull    =   and(logicMask, G_logic);                    
                    R_usefull    =   and(logicMask, R_logic);
                    
                    B_temp  =   obj.tmpBGR( Y_0 : Y_0 + Y_height-1, X_0 : X_0 + X_width-1 ,1 );
                    B_temp( B_usefull(Y_0 : Y_0 + Y_height-1, X_0 : X_0 + X_width-1 ) ) = 255;
                    B_temp( ~B_usefull(Y_0 : Y_0 + Y_height-1, X_0 : X_0 + X_width-1 ) ) = B(Y_0 : Y_0 + Y_height-1, X_0 : X_0 + X_width-1 );
                    B_temp  = cast(B_temp, 'int8' );
                    obj.tmpBGR( Y_0 : Y_0 + Y_height-1, X_0 : X_0 + X_width-1 ,1 ) = B_temp;
                    
                    G_temp  =   obj.tmpBGR( Y_0 : Y_0 + Y_height-1, X_0 : X_0 + X_width-1 ,2 );
                    G_temp( G_usefull(Y_0 : Y_0 + Y_height-1, X_0 : X_0 + X_width-1 ) ) = 255;
                    G_temp( ~G_usefull(Y_0 : Y_0 + Y_height-1, X_0 : X_0 + X_width-1 ) ) = G(Y_0 : Y_0 + Y_height-1, X_0 : X_0 + X_width-1 );
                    G_temp  = cast(G_temp, 'int8' );
                    obj.tmpBGR( Y_0 : Y_0 + Y_height-1, X_0 : X_0 + X_width-1 ,2 ) = G_temp;
                    
                    R_temp  =   obj.tmpBGR( Y_0 : Y_0 + Y_height-1, X_0 : X_0 + X_width-1 ,3 );
                    R_temp( R_usefull(Y_0 : Y_0 + Y_height-1, X_0 : X_0 + X_width-1 ) ) = 255;
                    R_temp( ~R_usefull(Y_0 : Y_0 + Y_height-1, X_0 : X_0 + X_width-1 ) ) = R(Y_0 : Y_0 + Y_height-1, X_0 : X_0 + X_width-1 );
                    R_temp  = cast(R_temp, 'int8' );
                    obj.tmpBGR( Y_0 : Y_0 + Y_height-1, X_0 : X_0 + X_width-1 ,3 ) = R_temp;
                    
                    tmpBGR_convertHSV           =   cv.cvtColor( obj.tmpBGR, 'BGR2HSV');       %   BGR2HSV     **BGR2HSV_FULL**
                    tmpBGR_convertHSV_castByte  =   cast( tmpBGR_convertHSV, 'int8');
                                
                    if isKey( obj.hsvConversionCache, mulFactors(i)) == 0
                                    
                        obj.hsvConversionCache(mulFactors(i))   =  tmpBGR_convertHSV_castByte;  
                                
                    end
                                
                        obj.tmpHSV  =  obj.hsvConversionCache(mulFactors(i));   % CONTROLLARE
                        output(index)    =   obj.CreateRealPatch( inputBGRframe, inputHSVframe, inputMask, 0, 1, inputRectangle);
                        index   =   index + 1; 
                end
                
                %   ATTENZIONE 0 , controllare i nomi dei parametri
                output(index) = obj.CreateRealPatch( obj.BGRframe, obj.HSVframe, inputMask, 0, 0, inputRectangle); 
            
            end
            output = 0;
        end
        
         
            
        
        
        
        function output = CreateRealPatch( obj, inputHSVframe, inputMask,...
                inputCheckCoverage, inputIsSimulated, inputRectangle)
            
            X_0     =   inputRectangle(1);
            X_width     =   inputRectangle(3);
            
            Y_0     =   inputRectangle(2);
            Y_height     =   inputRectangle(4);
            
            %   Se considero la lunghezza come x + width risulta width+1
            %   per questa ragione uso -1
            nonZeroPixels   =   cast(obj.CountNonZeroPixels( inputMask, X_0, X_0+X_width-1,...
                Y_0, Y_0+Y_height-1),'double');      
                       
            coverage        =   realmax;
            
            
            if  inputCheckCoverage
               
                mask_ROI_width  =   cast(X_width,'double');    
                mask_ROI_height =   cast(Y_height,'double');   
            
                area            =   mask_ROI_height * mask_ROI_width;
                coverage        =   nonZeroPixels / area;
                
            end
           
            %   Se la patch contiene un numero sufficiente di pixel
            %   dell'immagine eseguo l'if.
            if  coverage >= obj.parameters.DescCreation_minpatchCoverage
                
                %   Bin degli istogrammi.   
                binSizes1   =    obj.parameters.DescCreation_binSizes(1);
                binSizes2   =    obj.parameters.DescCreation_binSizes(2);
                binSizes3   =    obj.parameters.DescCreation_binSizes(3);
                featureVectSize     =   binSizes1 + binSizes2 + binSizes3;
               
                patch   =   Patch();
                patch.features  =   zeros(1,featureVectSize);
                
                Hstep   =   181 / binSizes1;   %   7.5417
                Sstep   =   256 / binSizes2;   %   21.3333
                Vstep   =   256 / binSizes3 ;  %   64
                
                inputHSVframe = cast(inputHSVframe( : , : , : ),'double');
                
                H   =   inputHSVframe( : , : , 1 );
                S   =   inputHSVframe( : , : , 2 );
                V   =   inputHSVframe( : , : , 3 );
                
                %   Converto la matrice maschera in una matrice logica.
                logicMask    =   inputMask == 0;
                
                %   Creo 3 matrici i cui valori corrispondono alle
                %   posizioni sul vettore feature a cui i valori H, S, e V
                %   dell'immagine corrispondono.
                %   Ad ogni valore H, S e V assegno un indice
                %   corrispondente ad una posizione sul vettore feature.
                indexH       =   cast( floor( H/Hstep),'int32') + 1;
                indexS       =   cast( floor( S/Sstep),'int32') + binSizes1 + 1;
                indexV       =   cast( floor( V/Vstep),'int32') + binSizes1 + binSizes2 + 1;
                
                %   Pongo a zero tutti i valori che si riferiscono a pixel
                %   del background.
                indexH(logicMask) = 0;
                indexS(logicMask) = 0;
                indexV(logicMask) = 0;
                
                %   Seleziono le regioni relative alla patch. 
                H_mask  =   indexH(Y_0 : Y_0 + Y_height-1, X_0 : X_0 + X_width-1 );
                S_mask  =   indexS(Y_0 : Y_0 + Y_height-1, X_0 : X_0 + X_width-1 );
                V_mask  =   indexV(Y_0 : Y_0 + Y_height-1, X_0 : X_0 + X_width-1 );
                
                %   Creo l'istogramma dei valori Hue.                
                for i = 1 : binSizes1
                    
                    %   Creo una matrice i cui valori true(1) corrispondono
                    %   agli indici i.
                    temp = H_mask == i;
                    
                    %   Conto quante ricorrenze dell'indice i possiedo e
                    %   inserisco il valore ottenuto nella posizione i del
                    %   vettore feature.
                    patch.features( i )  = nnz(temp);
                    
                end
                
                for i = binSizes1 + 1 : binSizes1 + binSizes2 
                    
                    temp = S_mask == i;
                    patch.features( i )  = nnz(temp);
                    
                end
                
                for i = binSizes1 + binSizes2 + 1 : featureVectSize
                    
                    temp = V_mask == i;
                    patch.features( i )  = nnz(temp);
                    
                end
                
                %   Normalizzo il vettore feature.
                patch.features   =   patch.features / cast(nonZeroPixels*3,'single');
                               
                patch.rect  =   inputRectangle;
                patch.isSimulated   =   inputIsSimulated;
                
                output  =   patch;
                
            else
                
                output  =   0;
                
            end
        end   
        
        %   Aumenta il contrasto dell'immagine.
        function output = Contrast(~, inputImage , inputContrast )
                        
            tmp     =   cast(inputImage,'single');
            translationMatrix  = 127 * ones( size(inputImage,1), size(inputImage,2), 3); 
            
            tmp     =   tmp - translationMatrix;
            tmp     =   inputContrast * tmp;
            tmp     =   tmp + translationMatrix;
                        
            %   Equivale al metodo Convert<Bgr, byte>() in C#
            tmp     =   cv.normalize(tmp,'NormType','MinMax','Alpha',0,'Beta',255,'DType','uint8');

            output  =   tmp;
            
            
        end   
        
        %   Gli operatori ChromaticBilateralOperator e SpatialCoveringOperator
        %   e i calcoli per y_TL e y_HT si riferiscono all'articolo:
        %   SDALF: Modeling Human Appearance with Symmetry-Driven Accumulation
        %   of Local Features, di Loris Bazzani, Marco Cristani and
        %   Vittorio Murino.
        
        %   L’operatore calcola la distanza Euclidea tra i valori dei pixel di
        %   due regioni dell’immagine, posizionate simmetricamente rispetto
        %   alla riga i-esima. Minore è la distanza tra le due regioni,
        %   maggiore è la loro somiglianza.
        function output = ChromaticBilateralOperator(~,inputHSVframe, inputY, inputDelta)  
        
            value   = 0;
            value   = cast(value,'double');
            inputY  = inputY+1;
            
            %   Eseguo un cast su tutta l'immagine per risparmeare tempo.
            %   Il codice C# effettuava un cast su ogni pixel selezionato.
            inputHSVframe   =   cast(inputHSVframe,'double'); 
            
            for row = 1 : inputDelta 
                
                HSVframe_width  =   size(inputHSVframe,2); 
                
                %   Il ciclo for che segue può essere eliminato. 
                %   Usando:
%                     up_Hue          =   inputHSVframe( inputY - row , :, 1);
%                     up_Saturation   =   inputHSVframe( inputY - row , :, 2);
%                     up_Value        =   inputHSVframe( inputY - row , :, 3);
%                     
%                     dn_Hue          =   inputHSVframe( inputY + row , :, 1);
%                     dn_Saturation   =   inputHSVframe( inputY + row , :, 2);
%                     dn_Value        =   inputHSVframe( inputY + row , :, 3);
%                     
%                     Hdiff   =   ( up_Hue - dn_Hue ) / 180;
%                     Sdiff   =   ( up_Saturation - dn_Saturation ) / 255;
%                     Vdiff   =   ( up_Value - dn_Value ) / 255;
%                     
%                     H   =   sum(Hdiff.*Hdiff,2);
%                     S   =   sum(Sdiff.*Sdiff,2);  
%                     V   =   sum(Vdiff.*Vdiff,2);
%
%                     value = value + H + S + V;
                %   Ho eseguito alcuni brevi test e i tempi d'esecuzione
                %   non sembrano diminuire. Bisogna eliminare entrambi i
                %   cicli per ottenere una riduzione.

                for x = 1 : HSVframe_width
                    
                    up_Hue          =   inputHSVframe( inputY - row , x, 1);
                    up_Saturation   =   inputHSVframe( inputY - row , x, 2);
                    up_Value        =   inputHSVframe( inputY - row , x, 3);
                    
                    dn_Hue          =   inputHSVframe( inputY + row , x, 1);
                    dn_Saturation   =   inputHSVframe( inputY + row , x, 2);
                    dn_Value        =   inputHSVframe( inputY + row , x, 3);
                    
                    Hdiff   =   ( up_Hue - dn_Hue ) / 180;
                    Sdiff   =   ( up_Saturation - dn_Saturation ) / 255;
                    Vdiff   =   ( up_Value - dn_Value ) / 255;
                    
                    value   =   value + ( Hdiff*Hdiff + Sdiff*Sdiff + Vdiff*Vdiff );    
                   
                end
                
            end
              
            output  =   sqrt(value) / inputDelta;
        end   
        
        
        %   Conteggia i pixel dell'individuo in due regioni ed
        %   effettua una sottrazione.
        function output = SpatialCoveringOperator(obj, inputMask, inputY, inputDelta)
                    
                mask_height     =   size(inputMask,1);
                mask_width      =   size(inputMask,2);
                inputDelta      =   cast(inputDelta,'int32');
                
            if  inputDelta == 0 %   Caso ComputeTorsoLegsAxis.
                           
                upPixelsCount   =   obj.CountNonZeroPixels( inputMask,...
                    1, mask_width, 1, inputY-1);
                
                dnPixelsCount   =   obj.CountNonZeroPixels( inputMask,...
                    1, mask_width, inputY+1, mask_height);
                
                sizeUP  =   mask_width*(inputY-1);
                sizeDN  =   mask_width*(mask_height - inputY);
                
                output  =   abs( ( upPixelsCount - dnPixelsCount )/( max( sizeUP , sizeDN )));
                
            else %  Caso ComputeHeadTorsoAxis.
                
                upPixelsCount   =   obj.CountNonZeroPixels( inputMask,...
                    1, mask_width, inputY-cast(inputDelta,'int8'), inputY);
            
                dnPixelsCount   =   obj.CountNonZeroPixels( inputMask,...
                    1, mask_width, inputY+1, inputY+1 + cast(inputDelta,'int8'));
                
                output  =   abs( upPixelsCount - dnPixelsCount );
            
            end
        end   
        
        %   Calcola l'asse y_HT.
        %   argmin(-S(i,delta)).
        function output = ComputeHeadTorsoAxis(obj, inputMask, input_y_TL)
            
           mask_height = size(inputMask,1);
           delta       = mask_height / 4;
           max         = realmin;                                                               
           y_HT        = 0;
           
           %    Il valore 5 è un parametro definito dagli autori 
           %    dell'algoritmo.
           for y = 5 : input_y_TL 
              
               functional   =   obj.SpatialCoveringOperator( inputMask, y, delta);
               if functional > max
               
                   max  =   functional;
                   y_HT =   y;
                   
               end 
           end
           
           output   =   y_HT;
        end   
        
        %   Calcola l'asse y_TL.
        %   argmin(1-C(i,delta)+S(i,delta)).
        function output = ComputeTorsoLegsAxis(obj, inputHSVframe, inputMask)
            
            mask_height = size(inputMask,1);
            delta       = mask_height / 4;
            min         = realmax;                                                               
            
            y_TL        = 0;
            HSVframe_height  = size(inputHSVframe,1);
            
            for y = delta : HSVframe_height-delta-1
                
                functional  = 0.5*( 1 - obj.ChromaticBilateralOperator( inputHSVframe, y, delta)) + 0.5*obj.SpatialCoveringOperator( inputMask, y, 0);
                if functional < min
                    
                    min  = functional;
                    y_TL = y;
                    
                end    
            end
            
            output  = y_TL;   
        end   
        
        function output = CountNonZeroPixels(~, inputMask, input_xStartIndex, input_xLastIndex, input_yStartIndex, input_yLastIndex)
            
            if  input_yStartIndex <=0
                    input_yStartIndex = 1;
            end
            
            countNonZero = nnz( inputMask( input_yStartIndex : input_yLastIndex, input_xStartIndex : input_xLastIndex ));
            
            output  =   countNonZero; 
        
        end
        
        
    
    end
end

