// SYMULACJA GRZYBA

// Instrukcja obsługi:
// [P] oraz [spacja] zatrzymują (i wznawiają) efekt rozrastania!
// [S] zapisuje screen do folderu, w którym znajduje się plik z kodem!

// Łatwe do zmiany (uzupełniaj na miajscu ?)
// 1. ilość agentów (int numAgents = ?), czyli ilość linii, które będą się tworzyć
// 2. wielkość liter (PFont font = createFont("SansSerif", ?, true))
// 3. litery/słowa (String[] letters = {"?", "?", "?", "?"})
// 4. obecność liter: zakomentuj/odkomentuj ( PFont font = createFont("SansSerif", 50, true); // ŁATWA ZMIANA - wielkość liter
//  guideCanvas.textFont(font);
//  guideCanvas.textAlign(CENTER, CENTER);
//  guideCanvas.fill(255);
//  guideCanvas.noStroke();)
// 5. obecność mózgów: zakomentuj/odkomentuj (//for (int i = 0; i < 3; i++) {
//  drawSideBrainOutline(guideCanvas, elemX[4 + i], elemY[4 + i], 75);
//  }
//  guideCanvas.endDraw();
//  guideCanvas.loadPixels(); 
// 6. wielkość rdzenia/centrum (float radius = ?)

int numAgents = 600; // ŁATWA ZMIANA - tym mniej, tym mniej linii będzie się tworzyć
Agent[] agents;       
PGraphics guideCanvas;           
PGraphics organicBoundaryCanvas; 
float[][] trailMap;   
int canvasSize = 800; 
boolean isPaused = false; 

// Pozycja centralnego punktu wzrostu
float coreX, coreY;

// Lista przechowująca współrzędne pikseli liter i mózgów
ArrayList<PVector> shapePixels = new ArrayList<PVector>();

// Parametry organicznej ramy dostępne globalnie
float boundaryBaseRadius = 340;
float boundaryNoiseMax;
float boundaryNoiseSeed;

void setup() {
  size(800, 800);           
  background(18, 16, 14);   
  
  trailMap = new float[canvasSize][canvasSize];
  
  // Losowanie pozycji centrum
  coreX = width / 2 + random(-100, 100);
  coreY = height / 2 + random(-100, 100);
  
  // Inicjalizacja losowych parametrów szumu dla unikalnej ramy
  boundaryNoiseMax = random(2.0, 5.0); 
  boundaryNoiseSeed = random(1000); 

  // Losowa rama o kształcie organicznym
  organicBoundaryCanvas = createGraphics(canvasSize, canvasSize);
  organicBoundaryCanvas.beginDraw();
  organicBoundaryCanvas.background(0); 
  organicBoundaryCanvas.fill(255);     
  organicBoundaryCanvas.noStroke();
  
  organicBoundaryCanvas.beginShape();
  float cx = canvasSize / 2;
  float cy = canvasSize / 2;
  
  for (float a = 0; a < TWO_PI; a += radians(1)) {
    float r = getBoundaryRadius(a);
    float x = cx + cos(a) * r;
    float y = cy + sin(a) * r;
    organicBoundaryCanvas.vertex(x, y);
  }
  organicBoundaryCanvas.endShape(CLOSE);
  organicBoundaryCanvas.endDraw();
  organicBoundaryCanvas.loadPixels();

  // Losowanie pozycji elementów
  float[] elemX = new float[7];
  float[] elemY = new float[7];
  float[] elemRadius = {45, 35, 40, 45, 65, 65, 65}; 

  for (int i = 0; i < 7; i++) {
    boolean validPosition = false;
    int attempts = 0;
    
    while (!validPosition && attempts < 2000) {
      float angle = random(TWO_PI);
      float distFromScreenCenter = random(110, 260);
      float rx = (width / 2) + cos(angle) * distFromScreenCenter;
      float ry = (height / 2) + sin(angle) * distFromScreenCenter;
      
      if (dist(rx, ry, coreX, coreY) < 130) {
        attempts++;
        continue;
      }
      
      int px = constrain(int(rx), 0, width - 1);
      int py = constrain(int(ry), 0, height - 1);
      if (brightness(organicBoundaryCanvas.pixels[py * width + px]) < 50) {
        attempts++;
        continue;
      }
      
      boolean overlap = false;
      for (int j = 0; j < i; j++) {
        float minRequiredDist = elemRadius[i] + elemRadius[j] + 25;
        if (dist(rx, ry, elemX[j], elemY[j]) < minRequiredDist) {
          overlap = true;
          break;
        }
      }
      
      if (!overlap) {
        elemX[i] = rx;
        elemY[i] = ry;
        validPosition = true;
      }
      attempts++;
    }
    
    if (!validPosition) {
      elemX[i] = width / 2 + (i - 3) * 70;
      elemY[i] = height / 2 + ((i % 2 == 0) ? -120 : 120);
    }
  }

  // Konfiguracja płótna pomocniczego (mapa atrakcji dla liter i mózgów)
  guideCanvas = createGraphics(canvasSize, canvasSize);
  guideCanvas.beginDraw();
  guideCanvas.background(0);
  guideCanvas.noFill();
  guideCanvas.stroke(255);   
  guideCanvas.strokeWeight(2); 
  
  // Rysowanie liter  //ŁATWA ZMIANA - Zakomentuj 5 linii niżej jeśli nie chcesz słów/liter
  PFont font = createFont("SansSerif", 50, true); // ŁATWA ZMIANA - wielkość liter
  guideCanvas.textFont(font);
  guideCanvas.textAlign(CENTER, CENTER);
  guideCanvas.fill(255);
  guideCanvas.noStroke();
  
  String[] letters = {"W", "I", "S", "K"}; // ŁATWA ZMIANA - słowa/litery, zawsze mysi być 4!
  for (int i = 0; i < 4; i++) {
    guideCanvas.text(letters[i], elemX[i], elemY[i]);
  }
  
  //// Rysowanie mózgów //ŁATWA ZMIANA - Odkomentuj 5 linii niżej jeśli chcesz mózgi
  //for (int i = 0; i < 3; i++) {
  //  drawSideBrainOutline(guideCanvas, elemX[4 + i], elemY[4 + i], 75);
  //}
  
  //guideCanvas.endDraw();
  //guideCanvas.loadPixels(); 
  
  // Przycięcie liter/mózgów do wnętrza organicznej ramy
  guideCanvas.loadPixels();
  for (int i = 0; i < guideCanvas.pixels.length; i++) {
    if (brightness(organicBoundaryCanvas.pixels[i]) < 50) {
      guideCanvas.pixels[i] = color(0);
    }
  }
  guideCanvas.updatePixels();
  
  // Zbieranie pikseli kształtów 
  for (int y = 0; y < canvasSize; y++) {
    for (int x = 0; x < canvasSize; x++) {
      int idx = x + y * width;
      if (brightness(guideCanvas.pixels[idx]) > 200) {
        shapePixels.add(new PVector(x, y));
        trailMap[x][y] = 0.9; 
      }
    }
  }
  
  // Inicjalizacja agentów
  agents = new Agent[numAgents];
  for (int i = 0; i < numAgents; i++) {
    agents[i] = new Agent();
  }
}

// Funkcja zwracająca promień ramy dla danego kąta
float getBoundaryRadius(float a) {
  float xoff = map(cos(a), -1, 1, 0, boundaryNoiseMax) + boundaryNoiseSeed;
  float yoff = map(sin(a), -1, 1, 0, boundaryNoiseMax) + boundaryNoiseSeed;
  return boundaryBaseRadius + map(noise(xoff, yoff), 0, 1, -90, 90);
}

void draw() {
  if (isPaused) return;

  // Stopniowe zanikanie śladów w tablicy trailMap w czasie
  for (int x = 0; x < canvasSize; x += 2) {
    for (int y = 0; y < canvasSize; y += 2) {
      trailMap[x][y] *= 0.93; 
    }
  }
  
  // Rysowanie gęstego centrum w losowej pozycji
  drawCentralCore();
  
  // Aktualizacja logiki oraz renderowanie graficzne wszystkich agentów
  loadPixels(); 
  for (int i = 0; i < agents.length; i++) {
    agents[i].update();  
    agents[i].display(); 
  }
  updatePixels(); 
}

// Obsługa klawiatury: Pauza ([Spacja] lub [P]) oraz Zapis zrzutu ekranu ([S])
void keyPressed() {
  if (key == 'p' || key == 'P' || key == ' ') {
    isPaused = !isPaused;
    if (isPaused) {
      println(">> ZATRZYMANO (Pauza). Naciśnij SPACJĘ lub P, aby wznowić.");
    } else {
      println(">> WZNOWIONO symulację.");
    }
  }
  if (key == 's' || key == 'S') {
    String filename = "slime-wisk-" + year() + month() + day() + "-" + hour() + minute() + second() + ".png";
    save(filename);
    println(">> Zapisano zrzut ekranu jako: " + filename);
  }
}

// Funkcja rysująca centralny rdzeń
void drawCentralCore() {
  float radius = 35;    //ŁATWA ZMIANA - wielkość rdzeń, tym mniej, tym będzie mniejszy 
  
  for (int x = int(coreX - radius); x <= coreX + radius; x++) {
    for (int y = int(coreY - radius); y <= coreY + radius; y++) {
      if (dist(x, y, coreX, coreY) < radius + noise(x * 0.05, y * 0.05) * 15) {
        int ix = constrain(x, 0, width - 1);
        int iy = constrain(y, 0, height - 1);
        trailMap[ix][iy] = 1.0; 
      }
    }
  }
}

// Profil mózgu
void drawSideBrainOutline(PGraphics pg, float x, float y, float sz) {
  pg.pushMatrix();
  pg.translate(x, y); 
  pg.noFill();
  pg.stroke(255);
  pg.strokeWeight(3);
  
  // 1. Główny kontur półkuli mózgowej
  pg.beginShape();
  pg.vertex(-sz * 0.45, sz * 0.1); 
  pg.bezierVertex(-sz * 0.55, -sz * 0.2, -sz * 0.3, -sz * 0.5, 0, -sz * 0.5); 
  pg.bezierVertex(sz * 0.3, -sz * 0.5, sz * 0.55, -sz * 0.2, sz * 0.45, sz * 0.1);
  pg.bezierVertex(sz * 0.3, sz * 0.3, 0, sz * 0.35, -sz * 0.2, sz * 0.25);
  pg.bezierVertex(-sz * 0.35, sz * 0.2, -sz * 0.4, sz * 0.15, -sz * 0.45, sz * 0.1);
  pg.endShape();
  
  // 2. Móżdżek
  pg.pushMatrix();
  pg.translate(sz * 0.28, sz * 0.32);
  pg.beginShape();
  pg.vertex(-sz * 0.15, -sz * 0.1);
  pg.bezierVertex(-sz * 0.2, sz * 0.1, sz * 0.1, sz * 0.2, sz * 0.18, 0);
  pg.bezierVertex(sz * 0.2, -sz * 0.1, -sz * 0.05, -sz * 0.15, -sz * 0.15, -sz * 0.1);
  pg.endShape();
  pg.popMatrix();
  
  // 3. Pień mózgu
  pg.beginShape();
  pg.vertex(sz * 0.05, sz * 0.35);
  pg.bezierVertex(sz * 0.1, sz * 0.45, sz * 0.05, sz * 0.55, sz * 0.0, sz * 0.6);
  pg.vertex(-sz * 0.08, sz * 0.55);
  pg.bezierVertex(-sz * 0.05, sz * 0.45, -sz * 0.05, sz * 0.38, -sz * 0.02, sz * 0.33);
  pg.endShape();
  
  // 4. Wewnętrzne bruzdy i zwoje kory
  pg.noFill();
  pg.beginShape();
  pg.vertex(-sz * 0.1, sz * 0.15);
  pg.bezierVertex(sz * 0.05, sz * 0.05, sz * 0.2, 0.0, sz * 0.3, -sz * 0.05);
  pg.endShape();
  
  pg.beginShape();
  pg.vertex(0, -sz * 0.25);
  pg.bezierVertex(-sz * 0.05, -sz * 0.1, -sz * 0.1, 0, -sz * 0.15, sz * 0.05);
  pg.endShape();
  
  pg.popMatrix();
}

// Klasa agenta
class Agent {
  float x, y;                
  float angle;               
  float speed = 1.8;         
  float sensorAngle = radians(35); 
  float sensorDist = 10.0;   
  
  Agent() {
    respawn(); 
  }
  
  void respawn() {
    if (shapePixels.size() > 0 && random(1.0) < 0.7) {
      PVector p = shapePixels.get(int(random(shapePixels.size())));
      x = p.x + random(-3, 3);
      y = p.y + random(-3, 3);
    } else {
      x = coreX + random(-20, 20);
      y = coreY + random(-20, 20);
    }
    angle = random(TWO_PI);
  }
  
  void update() {
    float senseL = sense(angle - sensorAngle);
    float senseC = sense(angle);
    float senseR = sense(angle + sensorAngle);
    
    float guideL = guideSample(angle - sensorAngle);
    float guideC = guideSample(angle);
    float guideR = guideSample(angle + sensorAngle);
    
    float totalL = senseL + guideL * 8.5; 
    float totalC = senseC + guideC * 8.5;
    float totalR = senseR + guideR * 8.5;
    
    float steerAngle = radians(18); 
    
    if (totalC > totalL && totalC > totalR) {
      angle += random(-0.05, 0.05); 
    } else if (totalL > totalR) {
      angle -= steerAngle;          
    } else if (totalR > totalL) {
      angle += steerAngle;          
    } else {
      angle += random(-0.2, 0.2);   
    }
    
    x += cos(angle) * speed;
    y += sin(angle) * speed;
    
    // Obliczanie dystansu do krawędzi ramy oraz odległości od środka ekranu
    float screenCenterX = width / 2;
    float screenCenterY = height / 2;
    float currentAngle = atan2(y - screenCenterY, x - screenCenterX);
    float maxDistToBorder = getBoundaryRadius(currentAngle);
    float distFromCenter = dist(screenCenterX, screenCenterY, x, y);
    float distToBoundary = maxDistToBorder - distFromCenter;
    
    if (distToBoundary <= 0) {
      respawn();
      return;
    }
    
    float normalizedDist = constrain(distFromCenter / maxDistToBorder, 0.0, 1.0);
    float centerThinningFactor = 1.0 - (normalizedDist * 0.75); 
    
    float taperZone = 40.0;
    float edgeFactor = 1.0;
    if (distToBoundary < taperZone) {
      edgeFactor = constrain(distToBoundary / taperZone, 0.0, 1.0);
    }
    
    float finalFactor = centerThinningFactor * edgeFactor;
    
    int ix = constrain(int(x), 0, width - 1);
    int iy = constrain(int(y), 0, height - 1);
    
    int brushSize = (finalFactor > 0.5) ? 1 : 0; 
    for (int bx = -brushSize; bx <= brushSize; bx++) {
      for (int by = -brushSize; by <= brushSize; by++) {
        int px = constrain(ix + bx, 0, width - 1);
        int py = constrain(iy + by, 0, height - 1);
        trailMap[px][py] = min(1.0, trailMap[px][py] + (0.5 * finalFactor)); 
      }
    }
  }
  
  float sense(float ang) {
    float sx = x + cos(ang) * sensorDist;
    float sy = y + sin(ang) * sensorDist;
    int ix = constrain(int(sx), 0, width - 1);
    int iy = constrain(int(sy), 0, height - 1);
    return trailMap[ix][iy];
  }
  
  float guideSample(float ang) {
    float sx = x + cos(ang) * sensorDist;
    float sy = y + sin(ang) * sensorDist;
    int ix = constrain(int(sx), 0, width - 1);
    int iy = constrain(int(sy), 0, height - 1);
    return brightness(guideCanvas.pixels[iy * width + ix]) / 255.0; 
  }
  
  void display() {
    int ix = constrain(int(x), 0, width - 1);
    int iy = constrain(int(y), 0, height - 1);
    float t = trailMap[ix][iy]; 
    
    if (t > 0.06) {
      int loc = ix + iy * width;
      
      // ======================================================================
      // PŁYNNY GRADIENT KOLORU W ZALEŻNOŚCI OD ODLEGŁOŚCI OD CENTRUM WZROSTU
      // ======================================================================
      float dFromCore = dist(ix, iy, coreX, coreY);
      float maxSpread = 320.0; // Maksymalny promień rozrostu
      float colorFactor = constrain(dFromCore / maxSpread, 0.0, 1.0);
      
      // Definicja palety barw:
      // - W centrum (core): głęboki, ciepły bursztyn/pomarańcz
      float rCenter = 255, gCenter = 140, bCenter = 20;
      // - W środkowej części: klasyczny żółty śluzowca
      float rMid   = 255, gMid   = 205, bMid   = 45;
      // - Na obrzeżach: limonkowy / seledynowy odcień
      float rEdge  = 165, gEdge  = 235, bEdge  = 65;
      
      float finalR, finalG, finalB;
      
      if (colorFactor < 0.5) {
        // Przejście od centrum do środkowego złota (0.0 - 0.5)
        float f = colorFactor * 2.0;
        finalR = lerp(rCenter, rMid, f);
        finalG = lerp(gCenter, gMid, f);
        finalB = lerp(bCenter, bMid, f);
      } else {
        // Przejście od środkowego złota do limonkowych obrzeży (0.5 - 1.0)
        float f = (colorFactor - 0.5) * 2.0;
        finalR = lerp(rMid, rEdge, f);
        finalG = lerp(gMid, gEdge, f);
        finalB = lerp(bMid, bEdge, f);
      }
      
      // Zastosowanie jasności śladu (t) do wyliczonego gradientu koloru
      pixels[loc] = color(finalR * t, finalG * t, finalB * t);
    }
  }
}
