% Per tancar totes les finestres anteriors i així estalviar-me tancar-les totes
close all;

% Path d'on estan ubicades les imatges
carpeta_imatges = 'C:\Users\neuso\OneDrive - URV\Documentos\MATLAB\final_p\Imatges cucs (prac)\WormImages';

% Llegeixo el fitxer CSV proporcionar
data = fullfile('C:\Users\neuso\OneDrive - URV\Documentos\MATLAB\final_p\Imatges cucs (prac)\', 'WormDataA.csv'); % Fitxer amb els resultats esperats

% Llegeixo les imatges del path "carpeta_imatges"
imatges = dir(fullfile(carpeta_imatges, '*.tif'));
total_imatges = length(imatges); % Guardo la longitud total de la imatge per més endavant

resultats_finals = 'resultats'; % La carpeta es diu "resultats"
if exist(resultats_finals, 'dir') % Miro si existeix aquest directori
    delete(fullfile(resultats_finals, '*')); % Si existeix, l'esborro per tornar-lo a crear amb les noves dades de la nova execució
else
    mkdir(resultats_finals); % En cas que no existeixi, el creo
end

% Variables a tractar que s'escriuran al CSV amb els resultats actualitzats
totes_imatges = (1:total_imatges)'; % Vector columna que conté totes les imatges
cuc_num = zeros(total_imatges, 1); % Inicialitzo com un vector columna de zeros amb la longitud de "total_imatges"
viu_num = zeros(total_imatges, 1); % Inicialitzo com un vector columna de zeros amb la longitud de "total_imatges"
mort_num = zeros(total_imatges, 1); % Inicialitzo com un vector columna de zeros amb la longitud de "total_imatges"
tipus = cell(total_imatges, 1); % Array de cel·les amb "total_imatges" files i 1 columna

% Llegeixo el fitxer CSV proporcionat
llegir_cucs = readtable(data); % Llegeixo el fitxer CSV proporcionat
morts_csv = llegir_cucs{:, 2}; % Extrec les dades de la segona columna i les guardo en un vector
vius_csv = llegir_cucs{:, 3}; % Extrec les dades de la tercera columna i les guardo en un vector

% Mida de l'àrea de contorn acceptable
area_minima = 50;

% Definir umbral per classificar cucs vius i morts manualment
umbral_circularity = 0.18; % Ajusta aquest valor segons sigui necessari

% Bucle per processar totes les imatges
for i = 1:total_imatges

    % Llegeixo la ruta de la imatge i la carrego a la variable imatge en forma de matriu
    imatge = imread(fullfile(carpeta_imatges, imatges(i).name));
    
    % Normalització de la imatge
    % L'utilitzo per millorar el contrast
    % Utilitzo el "adapthisteq" per millorar aquest contrast de petites regions (cucs)
    imatge_normalitzada = adapthisteq(imatge);
    
    % Utilitzo el mètode de OTSU per trobar un nivell de tall global
    threshold = graythresh(imatge_normalitzada);
    
    % Convertir la imatge normalitzada a una imatge binària
    imatge_binaria = imbinarize(imatge_normalitzada, threshold);
    
    % Eliminar objectes petits no desitjats
    imatge_binaria_processada = bwareaopen(imatge_binaria, 100);
    
    % Eliminar objectes en funció de l'àrea (menor que area_minima)
    % Aquesta línia elimina objectes de la imatge binària que tenen una àrea
    % menor que 'area_minima'. Això ajuda a eliminar soroll i objectes petits 
    % que no són cucs
    %imatge_binaria_processada = bwpropfilt(imatge_binaria_processada, 'Area', [area_minima Inf]);

    % Tractament de contorns
    % Aquesta línia troba els contorns dels objectes a la imatge binària processada
    % 'Etiqueta' conté una matriu etiquetada on cada objecte té una etiqueta única
    [contorns, Etiqueta] = bwboundaries(imatge_binaria_processada);

    % 'regionprops' calcula propietats de les regions etiquetades, com l'àrea,
    % el perímetre i el centroid. Aquestes propietats s'utilitzen més endavant
    % per classificar els cucs com a vius o morts segons la seva curvatura
    propietats = regionprops(Etiqueta, 'Area', 'Perimeter', 'Centroid');

    % Inicialització de comptadors per cucs vius i morts
    vius = 0;
    morts = 0;

    % Visualització de la imatge original per superposar els resultats
    figure;
    imshow(imatge);
    hold on;
    
    % Bucle per processar cada contorn trobat
    for k = 1:length(contorns)
        contorn = contorns{k};

        % Calcula l'àrea i el perímetre del contorn actual
        area_contorn = propietats(k).Area;
        perimetre_contorn = propietats(k).Perimeter;
       
    % Filtra contorns amb àrea menor que 'area_minima' i major que un límit superior
    % Aquest filtratge s'utilitza per evitar la classificació incorrecta d'objectes
    % que són massa petits per ser cucs o massa grans per ser considerats com un únic cuc.
         if ((area_contorn >= area_minima) && area_contorn < 5000)
            
            % Calcula la circularitat del contorn
            % La circularitat s'utilitza per determinar si un cuc està viu o mort.
            % Un valor de circularitat més baix indica un cuc mort (forma més irregular).
            circularity = (4 * pi * area_contorn) / (perimetre_contorn ^ 2);
            centroid = propietats(k).Centroid;
            
            % Classificació del cuc com a viu o mort basant-se en la circularitat
            if circularity < umbral_circularity
                morts = morts + 1;
                categoria = 'Mort';
                color_categoria = 'red';
            else
                vius = vius + 1;
                categoria = 'Viu';
                color_categoria = 'green';
            end
         end

        plot(contorn(:,2), contorn(:,1), 'Color', 'white', 'LineWidth', 1);
        text(centroid(1) + 10, centroid(2), categoria, 'Color', color_categoria, 'FontSize', 12);
    end
    
    title(['Detecció de cucs - Imatge ' num2str(i)]);
    text(10, 10, ['Cucs totals: ' num2str(vius + morts)], 'Color', 'white', 'FontSize', 12, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
    text(10, 30, ['Vius: ' num2str(vius)], 'Color', 'green', 'FontSize', 12, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
    text(10, 50, ['Morts: ' num2str(morts)], 'Color', 'red', 'FontSize', 12, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
    
    % Desem els comptadors
    cuc_num(i) = vius + morts;
    viu_num(i) = vius;
    mort_num(i) = morts;

    if vius > morts
        tipus{i} = 'alive';
    else
        tipus{i} = 'dead';
    end

    % Mostrar el nombre total de cucs vius i morts a la imatge
    %total_text = sprintf('Total Cuc(s): %d\nViu(s): %d\nMort(s): %d', vius + morts, vius, morts);
    %annotation('textbox', [0.8, 0.8, 0.1, 0.1], 'String', total_text, 'Color', 'black', 'FontSize', 12, 'BackgroundColor', 'white');

    %title(['Detecció de cucs - Imatge ', num2str(i)]);
    hold off;

    % Desar la imatge actual
    fig_nom = fullfile(resultats_finals, sprintf('image_%d.png', i));
    saveas(gcf, fig_nom);

        % Obtenim els valors esperats
    morts_esperats = morts_csv(i);
    vius_esperats = vius_csv(i);
    total_esperat = morts_esperats + vius_esperats;

    % Mostrem la comparació
    disp(['Imatge ', num2str(i), ':']);
    disp(['1. Cucs totals -> ', num2str(vius + morts), ' esperats -> ', num2str(total_esperat)]);
    disp(['2. Cucs Vius -> ', num2str(vius), ' esperats -> ', num2str(vius_esperats)]);
    disp(['3. Cucs Morts -> ', num2str(morts), ' esperats -> ', num2str(morts_esperats)]);
    disp('-----');
end

% Creem una taula per desar els resultats
taula = table(totes_imatges, cuc_num, viu_num, mort_num, tipus, 'VariableNames', {'Imatge', 'NumeroCucs', 'CucsVius', 'CucsMorts', 'Classificació'});

% Escrivim la taula al fitxer
writetable(taula, 'resultats/resultat.xlsx');

% Obtenim les etiquetes de la primera columna
etiquetes = llegir_cucs.File_Status;

% Split the labels to extract the 'alive' or 'dead' part
etiquetes_parts = split(etiquetes, ',');
etiqueta_estat = etiquetes_parts(:, 2);

% Comparem l'estat amb el resultat
prediccions_correctes = strcmp(tipus, etiqueta_estat);

% Calculem el total
total_prediccions = numel(prediccions_correctes);
disp(['Classificació de les imatges -> ', num2str(sum(prediccions_correctes))]);
disp(['Classificació esperada -> ', num2str(total_prediccions)]);
