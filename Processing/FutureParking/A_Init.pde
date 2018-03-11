/*  DRIVING FUTURES
 *  Ira Winder, ira@mit.edu, 2018
 *
 *  Init Functions (Superficially Isolated from FutureParking.pde)
 *
 *  MIT LICENSE:  Copyright 2018 Ira Winder
 *
 *               Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
 *               and associated documentation files (the "Software"), to deal in the Software without restriction, 
 *               including without limitation the rights to use, copy, modify, merge, publish, distribute, 
 *               sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is 
 *               furnished to do so, subject to the following conditions:
 *
 *               The above copyright notice and this permission notice shall be included in all copies or 
 *               substantial portions of the Software.
 *
 *               THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT 
 *               NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
 *               NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
 *               DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
 *               OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

// Counter to track which phase of initialization
int initPhase = 0;
int phaseDelay = 0;
String status[] = {
  "Loading Toolbars ...",
  "Importing Road Network ...",
  "Importing Parking Infrastructure ...",
  "Finding Shortest Paths ...",
  "Setting Up 3D Environment ...",
  "Calibrating Systems Model ...",
  "Populating Vehicles ...",
  "Finishing Up ...",
  "Ready to go!"
};
int NUM_PHASES = status.length;

void initialize() {
  
  if (initPhase == 0) {
    
    //  Parameter Space for Geometric Area
    //
    latCtr = +42.350;
    lonCtr = -71.066;
    tol    =  0.035;
    latMin = latCtr - tol;
    latMax = latCtr + tol;
    lonMin = lonCtr - tol;
    lonMax = lonCtr + tol;
    
  } else if (initPhase == 1) {
    
    // Initialize Toolbar
    //
    BAR_X = MARGIN;
    BAR_Y = MARGIN;
    BAR_W = 250;
    BAR_H = 800 - 2*MARGIN;
    
    // Initialize Left Toolbar
    bar_left = new Toolbar(BAR_X, BAR_Y, BAR_W, BAR_H, MARGIN);
    bar_left.title = "Driving Futures V1.1\n\n";
    //bar_left.credit = "I. Winder, D. Vasquez, K. Kusina,\nA. Starr, K. Silvester, JF Finn";
    bar_left.credit = "";
    bar_left.explanation = "Explore a hypothetical future of shared and autonomous vehicles.\n\n";
    bar_left.explanation += "[r] <- Press 'r' to reset sliders\n";
    bar_left.explanation += "[f] <- Press 'f' to show framerate";
    bar_left.controlY = BAR_Y + bar_left.margin + 4*bar_left.CONTROL_H;
    bar_left.addSlider("Year of Analysis",              "",  2010, 2030, 2018, 'q', 'w');
    bar_left.addSlider("Annual Vehicle Trip Growth",    "%", -2,      5,    3, 'Q', 'W');
    bar_left.addSlider("RideShare: System Equilibrium", "%", 0,     100,   60, 'a', 's');
    bar_left.addSlider("RideShare: Peak Hype",          "",  2010, 2030, 2018, 'A', 'S');
    bar_left.addSlider("AV: System Equilibrium",        "%",    0,  100,   90, 'z', 'x');
    bar_left.addSlider("AV: Peak Hype",                 "",  2010, 2030, 2024, 'Z', 'X');
    bar_left.addTriSlider("Parking\nVacancy\nPriority", "Below\nGround", belowColor, 
                                                        "Surface\nParking", surfaceColor, 
                                                        "Above\nGround", aboveColor);
    bar_left.addButton("BLANK", 0, true, ' '); // Spacer for Parking and Vehicle Button Lables
    bar_left.addButton("Below",               belowColor,    true, '1');
    bar_left.addButton("Surface",             surfaceColor,  true, '2');
    bar_left.addButton("Above",               aboveColor,    true, '3');
    bar_left.addButton("RSVD",                reservedColor, true, '4');
    bar_left.addButton("Private",             car1Color,     true, '5');
    bar_left.addButton("Shared",              car2Color,     true, '6');
    bar_left.addButton("AV Private",          car3Color,     true, '7');
    bar_left.addButton("AV Shared",           car4Color,     true, '8');
    bar_left.buttons.remove(0); // Remove blanks
    for (int i=0; i<4; i++) {   // Shift last 4 buttons right
      bar_left.buttons.get(i+4).xpos = bar_left.barX + bar_left.barW/2; 
      bar_left.buttons.get(i+4).ypos = bar_left.buttons.get(i).ypos;
    }
    
    // Initialize Right Toolbar
    bar_right = new Toolbar(width - (BAR_X + BAR_W), BAR_Y, BAR_W, BAR_H, MARGIN);
    bar_right.title = "[Analysis] System Projections";
    bar_right.credit = "";
    bar_right.explanation = "";
    bar_right.controlY = BAR_Y + bar_right.margin + bar_left.CONTROL_H;
    
  } else if (initPhase == 2) {
    
    initRoads();
    
  } else if (initPhase == 3) {
    
    initParking();
    
  } else if (initPhase == 4) {
    
    initPaths();
    
  } else if (initPhase == 5) {
    
    // Initialize the Camera
    // cam = new Camera(toolbar_width, b, -350, 50, 0.7, 0.1, 2.0, 0.45);
    // Initialize 3D World Camera Defaults
    cam = new Camera (B, MARGIN);
    // eX, eW (extentsX ...) prevents accidental dragging when interactiong with toolbar
    cam.eX = MARGIN + BAR_W;
    cam.eW = width - 2*(BAR_W + MARGIN);
    cam.X_DEFAULT    = -350;
    cam.Y_DEFAULT     =   50;
    cam.ZOOM_DEFAULT = 0.40;
    cam.ZOOM_POW     = 2.00;
    cam.ZOOM_MAX     = 0.20;
    cam.ZOOM_MIN     = 0.50;
    cam.ROTATION_DEFAULT = PI; // (0 - 2*PI)
    cam.enableChunks = false;  // Enable/Disable 3D mouse cursor field for continuous object placement
    cam.init(); //Must End with init() if any variables within Camera() are changed from default
    cam.off(); // turn cam off while still initializing
  
  } else if (initPhase == 6) {
    
    // Setup System Simulation
    sys = new Parking_System(1001, 2010, 2030);
    sys.av_growth = 1.0;
    sys.rideShare_growth = 1.0;
    sys.totBelow = structures.totBelow     / 100;
    sys.totSurface = structures.totSurface / 100;
    sys.totAbove = structures.totAbove     / 100;
    setSliders();
    sys.update();
    setParking();
  
  } else if (initPhase == 7) {
    
    // Initialize Vehicle Agents
    initPopulation();  
  
  } else if (initPhase == 8) {
    
    // Sample 3D objects to manipulate
    additions = new ArrayList<PVector>();
    
    initialized = true;
    
  }
  
  loadScreen(loadingBG, initPhase, NUM_PHASES, status[initPhase]);
  if (!initialized) initPhase++; 
  delay(phaseDelay);
}

void initRoads() {
  
  // Check for existance of JSON file
  //
  String fileName = "local/boston_OSM.json";
  graphJSON = new File(dataPath(fileName));
  boolean loadFile;
  if(graphJSON.exists()) { 
    loadFile = true;
  } else {
    loadFile = false;
    println("The specified file '" + fileName + "' is not present. Creating new one ... ");
  }
  
  // loadFile = false; // override! Turns out this doesn't really save much computational speed anyway ...
  
  // Graph pixel dimensions
  //
  int graphWidth  = int(B.x); // pixels
  int graphHeight = int(B.y); // pixels
    
  if (loadFile) {
    
    //  A Road Network Created from a JSON File compatible with Graph.loadJSON()
    //
    boolean drawNodes = false;
    boolean drawEdges = true;
    network = new Graph(graphWidth, graphHeight, fileName, drawNodes, drawEdges);
    
  } else {
    
    //  A Road Network Created from a QGIS OSM File
    //
    // Use this function rarely when you need to clean a csv file. It saves a new file to the data folder
    //rNetwork = new RoadNetwork("data/roads.csv", latMin, latMax, lonMin, lonMax);
    //
    rNetwork = new RoadNetwork("data/roads.csv");
    
    //  An example gridded network of width x height (pixels) and node resolution (pixels)
    //
    int nodeResolution = 5;     // pixels
    network = new Graph(graphWidth, graphHeight, latMin, latMax, lonMin, lonMax, nodeResolution, rNetwork);
    
    // Save network to JSON file
    //
    network.saveJSON(fileName);
  }
}

void initParking() {
  
  //  Init A list of parking structures
  //
  structures = new Parking_Structures(latMin, latMax, lonMin, lonMax);
  Table parkingCSV = loadTable("data/parking.csv", "header");
  
  for (int i=0; i<parkingCSV.getRowCount(); i++) {
    float x = parkingCSV.getFloat(i, "X");
    float y = parkingCSV.getFloat(i, "Y");
    float canvasX  = B.x * (x - lonMin) / abs(lonMax - lonMin);
    float canvasY  = B.y - B.y * (y - latMin) / abs(latMax - latMin);
    float area = parkingCSV.getFloat(i, "SHAPE_area");
    String type = parkingCSV.getString(i, "20171127_Parking Typology (use dropdown)");
    int capacity = parkingCSV.getInt(i, "20171127_Gensler Revised Parking Spots");
    Parking park = new Parking(canvasX, canvasY, area, type, capacity);
    park.respondent = parkingCSV.getString(i, "20171127_Respondent (First+ Last)");
    park.address    = parkingCSV.getString(i, "MAL");
    park.name       = parkingCSV.getString(i, "Proj_nam");
    park.devName    = parkingCSV.getString(i, "DevName");
    park.devAddy    = parkingCSV.getString(i, "DevAddy");
    park.parkMethod = parkingCSV.getString(i, "Park_type");
    park.userGroup  = parkingCSV.getString(i, "User_Group");
    
    String sub = ""; if (park.type.length() >= 3) sub = park.type.substring(0,3);
    if (sub.equals("Bel")) {
      park.col = belowColor;
      structures.totBelow += park.capacity;
    } else if (sub.equals("Sur")) {
      park.col = surfaceColor;
      structures.totSurface += park.capacity;
    } else if (sub.equals("Sta") || sub.equals("Abo")) {
      park.col = aboveColor;
      structures.totAbove += park.capacity;
    } else {
      park.col = reservedColor;
    } 
    
    if (capacity > 0) structures.parking.add(park);
  }
}

void initPaths() {
  
  // Check for existance of JSON file
  //
  String fileName = "local/routes.json";
  routesJSON = new File(dataPath(fileName));
  boolean loadFile;
  if(routesJSON.exists()) { 
    loadFile = true;
  } else {
    loadFile = false;
    println("The specified file '" + fileName + "' is not present. Creating new one ... ");
  }
  
  // loadFile = false;
  
  // Collection of routes to and from home, work, and parking ammentities
  if (loadFile) {
    routes = new Parking_Routes(int(B.x), int(B.y), fileName);
  } else {
    // generate randomly according to parking structures
    routes = new Parking_Routes(int(B.x), int(B.y), network, structures);
    routes.saveJSON(fileName);
  }
}

void initPopulation() {
  int yr = sys.year_now - sys.year_0;
  
  type1 = new ArrayList<Agent>();
  type2 = new ArrayList<Agent>();
  type3 = new ArrayList<Agent>();
  type4 = new ArrayList<Agent>();
  
  for (int i=0; i<sys.numCar1[yr]; i++) addVehicle(type1, "1");
  for (int i=0; i<sys.numCar2[yr]; i++) addVehicle(type2, "2");
  for (int i=0; i<sys.numCar3[yr]; i++) addVehicle(type3, "3");
  for (int i=0; i<sys.numCar4[yr]; i++) addVehicle(type4, "4");
}

PImage loadingBG;
void loadScreen(PImage bg, int phase, int numPhases, String status) {
  image(bg, 0, 0, width, height);
  pushMatrix(); translate(width/2, height/2);
  int lW = 400;
  int lH = 48;
  int lB = 10;
  
  // Draw Loading Bar Outline
  noStroke(); fill(255, 200);
  rect(-lW/2, -lH/2, lW, lH, lH/2);
  noStroke(); fill(0, 200);
  rect(-lW/2+lB, -lH/2+lB, lW-2*lB, lH-2*lB, lH/2);
  
  // Draw Loading Bar Fill
  float percent = float(phase)/numPhases;
  noStroke(); fill(255, 150);
  rect(-lW/2 + lH/4, -lH/4, percent*(lW - lH/2), lH/2, lH/4);
  
  textAlign(CENTER, CENTER); fill(255);
  text(status, 0, 0);
  
  popMatrix();
}

void addVehicle(ArrayList<Agent> array, String type) {
  //  An example population that traverses along shortest path calculation
  //  FORMAT: Agent(x, y, radius, speed, path);
  //
  Agent vehicle;
  PVector loc;
  int random_waypoint;
  float random_speed;
  
  Path random;
  boolean loop = true;
  boolean teleport = true;
  
  random = routes.paths.get( int(random(routes.paths.size())) );
  int wpts = random.waypoints.size();
  while (wpts < 2) {
    random = routes.paths.get( int(random(routes.paths.size())) );
    wpts = random.waypoints.size();
  }
  random_waypoint = int(random(random.waypoints.size()));
  random_speed = 3.0*random(0.3, 0.4);
  loc = random.waypoints.get(random_waypoint);
  vehicle = new Agent(loc.x, loc.y, 2, random_speed, random.waypoints, loop, teleport, "RIGHT", type);
  array.add(vehicle);
}