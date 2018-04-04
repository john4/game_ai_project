class PlayerState {
  int STEP_FOOD_DEPLETION = 1000;
  int STEP_BIRTH = 2000;
  // int STEP_BIRTH = 100;  // for testing purposes

  ArrayList<Building> buildings;
  ArrayList<Citizen> citizens;
  ArrayList<Soldier> soldiers;

  double foodDepletionIndex;
  double birthIndex;

  int foodSupply;
  int lumberSupply;
  int populationCapacity;
  int oreSupply;

  BuildingCode placingBuilding;

  PlayerState() {
    // Assumes map has been generated
    // Place town square, add initial Humans and supplies
    buildings = new ArrayList<Building>();
    citizens = new ArrayList<Citizen>();
    soldiers = new ArrayList<Soldier>();

    foodDepletionIndex = STEP_FOOD_DEPLETION;
    birthIndex = 0;

    // Add town center to random grass cell
    while (true) {
      int townRow = int(random(boardMap.numRows));
      int townCol = int(random(boardMap.numCols));
      if (boardMap.cells[townRow][townCol].terraintype == 0) {
        buildings.add(new TownSquare(boardMap.cells[townRow][townCol]));
        buildings.add(new Farm(boardMap.cells[townRow - 2][townCol - 2]));
        break;
      }
    }

    foodSupply = 12;
    lumberSupply = 12;
    populationCapacity = 5;
    placingBuilding = BuildingCode.NONE;

    int cellSize = boardMap.gridsize;
    int rows = boardMap.numRows;
    int cols = boardMap.numCols;
  }
// int c = 0;
  void step(double gameStateIndex) {
    // Iterate states of all Humans, update game stats (food levels, etc.)

    // Food depletion
    if (gameStateIndex >= foodDepletionIndex) {
      int foodEaten = citizens.size() + (soldiers.size() * 2);
      foodSupply -= foodEaten;
      foodDepletionIndex += STEP_FOOD_DEPLETION;
    }

    // Births
    // TODO: add new citizens at hovels if we have any
    // add a true here and uncomment counter code to quickly generate citizens
    if (citizens.size() + soldiers.size() < populationCapacity && gameStateIndex >= birthIndex) {
      // if(c>30) {
      //   return;
      // }
      citizens.add(new FreeCitizen(buildings.get(0).loc, buildings.get(0), this));
      // citizens.add(new FreeCitizen(boardMap.cells[int(random(boardMap.numRows))][int(random(boardMap.numCols))], buildings.get(0)));
      birthIndex += STEP_BIRTH;
      // c++;
    }

    gameStateIndex += 1;
  }

  void draw() {
    for (Building building : buildings) {
      building.draw();
    }
    for (Citizen citizen : citizens) {
      citizen.draw();
    }
    for (Soldier soldier : soldiers) {
      soldier.draw();
    }
  }

  void placeBuilding(Cell loc) {
    this.addBuilding(this.placingBuilding, loc);
    this.placingBuilding = BuildingCode.NONE;
  }

  void addBuilding(BuildingCode b, Cell loc) {
    switch (b) {
      case FARM:
        this.buildings.add(new Farm(loc));
        break;
      case HOVEL:
        this.buildings.add(new Hovel(loc));
        break;
      case SAWMILL:
        this.buildings.add(new Sawmill(loc));
        break;
      case STOCKPILE:
        this.buildings.add(new Stockpile(loc));
        break;
    }
  }

  // Get the first unoccupied citizen, else null
  Citizen getFreeCitizen() {
    for (Citizen citizen : citizens) {
      if (citizen.isFree()) {
        return citizen;
      }
    }
    return null;
  }

  void addLumberjack() {
    Citizen freeCitizen = getFreeCitizen();
    if (freeCitizen != null) {
      citizens.add(new Lumberjack(freeCitizen.loc, buildings.get(0), this));
      citizens.remove(freeCitizen);
    }
  }

  void removeLumberjack() {
    for (Citizen citizen : citizens) {
      if (citizen instanceof Lumberjack) {
        citizens.add(new FreeCitizen(citizen.loc, buildings.get(0), this));
        citizens.remove(citizen);
        break;
      }
    }
  }

  void addFarmer() {
    Citizen freeCitizen = getFreeCitizen();
    if (freeCitizen != null) {
      citizens.add(new Farmer(freeCitizen.loc, buildings.get(1), this));
      citizens.remove(freeCitizen);
    }
  }

  void removeFarmer() {
    for (Citizen citizen : citizens) {
      if (citizen instanceof Farmer) {
        citizens.add(new FreeCitizen(citizen.loc, buildings.get(0), this));
        citizens.remove(citizen);
        break;
      }
    }
  }

  void addSoldier() {
    Citizen freeCitizen = getFreeCitizen();
    if (freeCitizen != null) {
      soldiers.add(new Soldier(freeCitizen.loc, buildings.get(0), this));
      citizens.remove(freeCitizen);
    }
  }

  void removeSoldier() {
    Soldier s = soldiers.get(0);
    citizens.add(new FreeCitizen(s.loc, buildings.get(0), this));
    soldiers.remove(s);
  }

  void addMiner() {
    Citizen freeCitizen = getFreeCitizen();
    if (freeCitizen != null) {
      citizens.add(new Miner(freeCitizen.loc, buildings.get(0), this));
      citizens.remove(freeCitizen);
    }
  }

  void removeMiner() {
    for (Citizen citizen : citizens) {
      if (citizen instanceof Miner) {
        citizens.add(new FreeCitizen(citizen.loc, buildings.get(0), this));
        citizens.remove(citizen);
        break;
      }
    }
  }
}
