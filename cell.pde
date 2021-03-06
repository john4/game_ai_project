import java.util.HashSet;

class Cell {
  ArrayList<Building> buildings = new ArrayList<Building>();
  Cell north, south, east, west;
  Cell northeast, northwest, southeast, southwest;
  int terraintype;          // value that determines the cell's type. Water, grass, forest, etc..
  int x, y;                 // the coordinates of the upper left corner of a cell
  int i, j;                 // i is width, j is height in grid
  PVector pos;              // the position of the center of the cell
  int[] nb = new int[5];    // number of terraintypes the neighbours have
  int gridsize;

  Cell(int gridi, int gridj, int type, int gridsize) {
    this.gridsize = gridsize;
    i = gridi;
    j = gridj;
    terraintype = type;
    x = i * gridsize;
    y = j * gridsize;
    pos = new PVector(x + gridsize/2, y + gridsize/2);
  }

  void show() {
    switch(terraintype) {
    case 0: //grass
      fill(103, 255, 109);
      break;
    case 1: // stone
      fill(160, 160, 160);
      break;
    case 2: //forest
      fill(0, 100, 4);
      break;
    case 3: // boundary
      fill(0);
      break;
    case 4: // sand
      fill(255, 231, 5);
      break;
    case 5: // water
      fill(0, 0, 255);
      break;
    case 6:
      fill(255, 0, 0);
      break;
    }

    noStroke();
    rect(x, y, gridsize, gridsize);
  }

  String getTerrainName() {
    switch(terraintype) {
    case 0:
      return "grass";
    case 1:
      return "stone";
    case 2:
      return "forest";
    case 3:
      return "boundary";
    case 4:
      return "sand";
    case 5:
      return "water";
    default:
      return "nothing";
    }
  }

  // Returns true if the given position is within the bounds of this cell
  boolean isIn(float posX, float posY) {
    return x < posX && posX < x + gridsize && y < posY && posY < y + gridsize;
  }

  void addBuilding(Building building) {
    buildings.add(building);
  }

  boolean hasBuilding() {
    return buildings.size() > 0;
  }

  boolean hasImpass(Building b) {
    for (Building building : buildings) {
      if (building.impassable) {
        return !building.equals(b);
      }
    }
    return false;
  }

  float euclideanDistanceTo(Cell o) {
    return this.euclideanDistanceTo(o.pos.x, o.pos.y);
  }

  float euclideanDistanceTo(float x0, float y0) {
    return (float) (Math.sqrt(Math.pow(pos.x - x0, 2) + Math.pow(pos.y - y0, 2)));
  }

  ArrayList<Cell> getNeighbors() {
    ArrayList<Cell> neighbors = new ArrayList<Cell>();
    neighbors.add(this.north);
    neighbors.add(this.south);
    neighbors.add(this.east);
    neighbors.add(this.west);
    neighbors.add(this.northeast);
    neighbors.add(this.northwest);
    neighbors.add(this.southeast);
    neighbors.add(this.southwest);
    return neighbors;
  }

  ArrayList<Cell> getCardinalNeighbors() {
    ArrayList<Cell> neighbors = new ArrayList<Cell>();
    neighbors.add(this.north);
    neighbors.add(this.south);
    neighbors.add(this.east);
    neighbors.add(this.west);
    return neighbors;
  }

  HashSet<Cell> getNearbyGrassCells(int r) {
    HashSet<Cell> set = new HashSet<Cell>();
    return getNearbyGrassCells(r, set);
  }

  HashSet<Cell> getNearbyGrassCells(int r, HashSet<Cell> initialSet) {
    initialSet.add(this);
    return getNearbyGrassCellsHelper(this, r, initialSet);
  }

  private HashSet<Cell> getNearbyGrassCellsHelper(Cell origin, int r, HashSet<Cell> acc) {
    for (Cell neighbor : this.getCardinalNeighbors()) {
      if (neighbor != null && neighbor.terraintype == 0 && !acc.contains(neighbor) && origin.euclideanDistanceTo(neighbor) <= r) {
        acc.add(neighbor);
        neighbor.getNearbyGrassCellsHelper(origin, r, acc);
      }
    }
    return acc;
  }

  boolean isNearCellOfType(int type, int hops) {
    return isNearCellOfTypeHelper(type, 1, hops);
  }

  private boolean isNearCellOfTypeHelper(int type, int nthHop, int hops) {
    if (nthHop > hops) {
      return false;
    }
    if (this.terraintype == type) {
      return true;
    }

    for (Cell neighbor : this.getCardinalNeighbors()) {
      if (neighbor != null && neighbor.isNearCellOfTypeHelper(type, nthHop + 1, hops)) {
        return true;
      }
    }
    return false;
  }

  /** Breadth-first find closest cell of type terrain */
  Cell findClosestOfType(int terrain) {
    ArrayList<Cell> openSet = new ArrayList<Cell>();
    ArrayList<Cell> closedSet = new ArrayList<Cell>();
    ArrayList<Cell> cellsWithBuildings = new ArrayList<Cell>();

    for (Building b : state.getBuildings()) {
      cellsWithBuildings.add(b.loc);
    }

    openSet.add(this);

    while (openSet.size() > 0) {
      Cell toCheck = openSet.get(0);
      openSet.remove(0);

      if (toCheck == null) {
        continue;
      }

      if (toCheck.terraintype == terrain && !cellsWithBuildings.contains(toCheck)) {
        return toCheck;
      }

      for (Cell neighbor : toCheck.getNeighbors()) {
        if (closedSet.contains(neighbor) || cellsWithBuildings.contains(neighbor)) {
          continue;
        }

        if (!openSet.contains(neighbor)) {
          openSet.add(neighbor);
        }
      }

      closedSet.add(toCheck);
    }

    return null;
  }
}
