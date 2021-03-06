import java.util.Arrays;

class Hal {
  static final int ACTION_COOLDOWN = 30;
  double cooldownIndex;
  static final int DESIRED_RESOURCE_BUILDING_PROXIMITY_TO_STOCKPILE = 30;
  static final int DESIRED_FARM_PROXIMITY_TO_STOCKPILE = 25;
  static final int CELLS_AROUND_TOWN_SQUARE_RADIUS = 100;

  GameState gameState;
  PlayerState computerState;
  PlayerState humanState;
  Building townSquare;
  ArrayList<Cell> grassCellsNearbyTownSquare;
  ArrayList<Cell> grassCellsNearForest;
  ArrayList<Cell> grassCellsNearStone;
  ArrayList<Cell> grassCellsNearStockpiles;
  ArrayList<Cell> grassCellsNearDesiredBuildingForStockpileProximity;
  CallbackMarker newStockpileBuilt = new CallbackMarker();
  CallbackMarker newSawmillOrFoundryBuilt = new CallbackMarker();
  HashMap<HumanCode, Float> goldenRatio;

  HalTask behaviorTree;

  Hal(GameState gameState, PlayerState computerState, PlayerState humanState) {
    this.gameState = gameState;
    this.computerState = computerState;
    this.humanState = humanState;

    this.goldenRatio = new HashMap<HumanCode, Float>();
    this.goldenRatio.put(HumanCode.FARMER, 13.0 / 32.0);
    this.goldenRatio.put(HumanCode.LUMBERJACK, 6.0 / 32.0);
    this.goldenRatio.put(HumanCode.MINER, 3.0 / 32.0);
    this.goldenRatio.put(HumanCode.SOLDIER, 10.0 / 32.0);

    cooldownIndex = gameState.gameStateIndex;

    townSquare = computerState.buildings.get(BuildingCode.TOWNSQUARE).get(0);
    HashSet<Cell> grassCellsNearbyTownSquareSet = townSquare.loc.getNearbyGrassCells(CELLS_AROUND_TOWN_SQUARE_RADIUS);
    grassCellsNearbyTownSquare = new ArrayList<Cell>(Arrays.asList(grassCellsNearbyTownSquareSet.toArray(new Cell[grassCellsNearbyTownSquareSet.size()])));
    grassCellsNearStockpiles = new ArrayList<Cell>();
    grassCellsNearForest = new ArrayList<Cell>();
    grassCellsNearStone = new ArrayList<Cell>();
    grassCellsNearDesiredBuildingForStockpileProximity = new ArrayList<Cell>();

    PotentialCells potentialGeneralCells = new PotentialCells(grassCellsNearbyTownSquare);
    PotentialCells potentialFarmCells = new PotentialCells(grassCellsNearStockpiles, grassCellsNearbyTownSquare);
    PotentialCells potentialSawmillCells = new PotentialCells(grassCellsNearForest, grassCellsNearbyTownSquare);
    PotentialCells potentialFoundryCells = new PotentialCells(grassCellsNearStone, grassCellsNearbyTownSquare);
    PotentialCells potentialStockpileProximityCells = new PotentialCells(grassCellsNearDesiredBuildingForStockpileProximity);

    for (Cell cell : grassCellsNearbyTownSquare) {
      if (cell.isNearCellOfType(1, 3)) {
        grassCellsNearStone.add(cell);
      }
      if (cell.isNearCellOfType(2, 3)) {
        grassCellsNearForest.add(cell);
      }
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////
    // COMBAT MODE ////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////

    HalTask becomeOffensive = new ChangeCombatMode(computerState, CombatMode.OFFENSIVE);
    HalTask becomeDefensive = new ChangeCombatMode(computerState, CombatMode.DEFENSIVE);

    HalTask[] shouldBecomeOffensiveSelectorItems = new HalTask[2];
    shouldBecomeOffensiveSelectorItems[0] = new EnemyArmyWeak(computerState, humanState);
    shouldBecomeOffensiveSelectorItems[1] = new HaveLargeArmy(computerState);
    HalTask shouldBecomeOffensiveSelector = new HalSelector(shouldBecomeOffensiveSelectorItems);

    HalTask[] becomeOffensiveSequenceItems = new HalTask[2];
    becomeOffensiveSequenceItems[0] = shouldBecomeOffensiveSelector;
    becomeOffensiveSequenceItems[1] = becomeOffensive;
    HalTask becomeOffensiveSequence = new HalSequence(becomeOffensiveSequenceItems);

    HalTask[] shouldBecomeDefensiveSelectorItems = new HalTask[2];
    shouldBecomeDefensiveSelectorItems[0] = new EnemyTroopsNearby(townSquare.loc, humanState);
    shouldBecomeDefensiveSelectorItems[1] = new HaveSmallArmy(computerState);
    HalTask shouldBecomeDefensiveSelector = new HalSelector(shouldBecomeDefensiveSelectorItems);

    HalTask[] becomeDefensiveSequenceItems = new HalTask[2];
    becomeDefensiveSequenceItems[0] = shouldBecomeDefensiveSelector;
    becomeDefensiveSequenceItems[1] = becomeDefensive;
    HalTask becomeDefensiveSequence = new HalSequence(becomeDefensiveSequenceItems);

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // PLACE BUILDING ////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////

    HalTask[] placeHovelSequenceItems = new HalTask[2];
    placeHovelSequenceItems[0] = new CanPlaceX(BuildingCode.HOVEL, computerState);
    placeHovelSequenceItems[1] = new PlaceX(BuildingCode.HOVEL, computerState, potentialGeneralCells);
    HalTask placeHovelSequence = new HalSequence(placeHovelSequenceItems);

    HalTask[] increasePopulationItems = new HalTask[2];
    increasePopulationItems[0] = new NeedMoreCitizens(computerState);
    increasePopulationItems[1] = placeHovelSequence;
    HalTask increasePopulationSequence = new HalSequence(increasePopulationItems);

    HalTask[] placeFarmSequenceItems = new HalTask[2];
    placeFarmSequenceItems[0] = new CanPlaceX(BuildingCode.FARM, computerState);
    placeFarmSequenceItems[1] = new PlaceX(BuildingCode.FARM, computerState, potentialFarmCells);
    HalTask placeFarmSequence = new HalSequence(placeFarmSequenceItems);

    HalTask[] placeFarmSelectorItems = new HalTask[2];
    placeFarmSelectorItems[0] = new CheckHaveBuilding(computerState, BuildingCode.FARM);
    placeFarmSelectorItems[1] = placeFarmSequence;
    HalTask placeFarmSelector = new HalSelector(placeFarmSelectorItems);

    HalTask[] placeSawmillSequenceItems = new HalTask[2];
    placeSawmillSequenceItems[0] = new CanPlaceX(BuildingCode.SAWMILL, computerState);
    placeSawmillSequenceItems[1] = new PlaceX(BuildingCode.SAWMILL, computerState, potentialSawmillCells, newSawmillOrFoundryBuilt);
    HalTask placeSawmillSequence = new HalSequence(placeSawmillSequenceItems);

    HalTask[] placeSawmillSelectorItems = new HalTask[2];
    placeSawmillSelectorItems[0] = new CheckHaveBuilding(computerState, BuildingCode.SAWMILL);
    placeSawmillSelectorItems[1] = placeSawmillSequence;
    HalTask placeSawmillSelector = new HalSelector(placeSawmillSelectorItems);

    HalTask[] placeFoundrySequenceItems = new HalTask[2];
    placeFoundrySequenceItems[0] = new CanPlaceX(BuildingCode.FOUNDRY, computerState);
    placeFoundrySequenceItems[1] = new PlaceX(BuildingCode.FOUNDRY, computerState, potentialFoundryCells, newSawmillOrFoundryBuilt);
    HalTask placeFoundrySequence = new HalSequence(placeFoundrySequenceItems);

    HalTask[] placeFoundrySelectorItems = new HalTask[2];
    placeFoundrySelectorItems[0] = new CheckHaveBuilding(computerState, BuildingCode.FOUNDRY);
    placeFoundrySelectorItems[1] = placeFoundrySequence;
    HalTask placeFoundrySelector = new HalSelector(placeFoundrySelectorItems);

    HalTask[] placeBarracksSequenceItems = new HalTask[2];
    placeBarracksSequenceItems[0] = new CanPlaceX(BuildingCode.BARRACKS, computerState);
    placeBarracksSequenceItems[1] = new PlaceX(BuildingCode.BARRACKS, computerState, potentialGeneralCells);
    HalTask placeBarracksSequence = new HalSequence(placeBarracksSequenceItems);

    HalTask[] placeBarracksSelectorItems = new HalTask[2];
    placeBarracksSelectorItems[0] = new CheckHaveBuilding(computerState, BuildingCode.BARRACKS);
    placeBarracksSelectorItems[1] = placeBarracksSequence;
    HalTask placeBarracksSelector = new HalSelector(placeBarracksSelectorItems);

    HalTask[] placeStockpileSequenceItems = new HalTask[2];
    placeStockpileSequenceItems[0] = new CanPlaceX(BuildingCode.STOCKPILE, computerState);
    placeStockpileSequenceItems[1] = new PlaceX(BuildingCode.STOCKPILE, computerState, potentialGeneralCells, newStockpileBuilt);
    HalTask placeStockpileSequence = new HalSequence(placeStockpileSequenceItems);

    HalTask[] placeStockpileSelectorItems = new HalTask[2];
    placeStockpileSelectorItems[0] = new CheckHaveBuilding(computerState, BuildingCode.STOCKPILE);
    placeStockpileSelectorItems[1] = placeStockpileSequence;
    HalTask placeStockpileSelector = new HalSelector(placeStockpileSelectorItems);

    HalTask[] placeProximityStockpileSelectorItems = new HalTask[1];
    placeProximityStockpileSelectorItems[0] = new PlaceProximityStockpile(BuildingCode.STOCKPILE, computerState, potentialStockpileProximityCells, newStockpileBuilt);
    HalTask placeProximityStockpileSelector = new HalSelector(placeProximityStockpileSelectorItems);

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    // ASSIGN CITIZENS ////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////

    HalTask[] assignFarmerSequenceItems = new HalTask[3];
    assignFarmerSequenceItems[0] = new CheckBelowGoldenRatio(computerState, HumanCode.FARMER, this.goldenRatio);
    assignFarmerSequenceItems[1] = placeFarmSelector;
    assignFarmerSequenceItems[2] = new AssignCitizen(computerState, HumanCode.FARMER);
    HalTask assignFarmerSequence = new HalSequence(assignFarmerSequenceItems);

    HalTask[] assignLumberjackSequenceItems = new HalTask[3];
    assignLumberjackSequenceItems[0] = new CheckBelowGoldenRatio(computerState, HumanCode.LUMBERJACK, this.goldenRatio);
    assignLumberjackSequenceItems[1] = placeSawmillSelector;
    assignLumberjackSequenceItems[2] = new AssignCitizen(computerState, HumanCode.LUMBERJACK);
    HalTask assignLumberjackSequence = new HalSequence(assignLumberjackSequenceItems);

    HalTask[] assignMinerSelectorItems = new HalTask[3];
    assignMinerSelectorItems[0] = new CheckBelowGoldenRatio(computerState, HumanCode.MINER, this.goldenRatio);
    assignMinerSelectorItems[1] = placeFoundrySelector;
    assignMinerSelectorItems[2] = new AssignCitizen(computerState, HumanCode.MINER);
    HalTask assignMinerSequence = new HalSequence(assignMinerSelectorItems);

    HalTask[] assignSoldierSelectorItems = new HalTask[3];
    assignSoldierSelectorItems[0] = new CheckBelowGoldenRatio(computerState, HumanCode.SOLDIER, this.goldenRatio);
    assignSoldierSelectorItems[1] = placeBarracksSelector;
    assignSoldierSelectorItems[2] = new AssignCitizen(computerState, HumanCode.SOLDIER);
    HalTask assignSoldierSequence = new HalSequence(assignSoldierSelectorItems);

    //////////////////////////////////////////////////////////////////////////////////////////
    // ORACLE ////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////

    HalTask[] oracleAssignSelectorItems = new HalTask[5];
    oracleAssignSelectorItems[0] = assignFarmerSequence;
    oracleAssignSelectorItems[1] = assignLumberjackSequence;
    oracleAssignSelectorItems[2] = assignMinerSequence;
    oracleAssignSelectorItems[3] = assignSoldierSequence;
    oracleAssignSelectorItems[4] = placeProximityStockpileSelector;
    HalTask oracleAssignSelector = new HalSelector(oracleAssignSelectorItems);

    HalTask[] oracleAssignSequenceItems = new HalTask[3];
    oracleAssignSequenceItems[0] = new HaveFreeCitizen(computerState);
    oracleAssignSequenceItems[1] = placeStockpileSelector;
    oracleAssignSequenceItems[2] = oracleAssignSelector;
    HalTask oracleAssignSequence = new HalSequence(oracleAssignSequenceItems);

    HalTask[] oracleItems = new HalTask[2];
    oracleItems[0] = increasePopulationSequence;
    oracleItems[1] = oracleAssignSequence;
    HalTask oracle = new HalSelector(oracleItems);

    //////////////////////////////////////////////////////////////////////////////////////////
    // WAR TABLE /////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////

    HalTask[] combatModeDecisionSelectorItems = new HalTask[2];
    combatModeDecisionSelectorItems[0] = becomeDefensiveSequence;
    combatModeDecisionSelectorItems[1] = becomeOffensiveSequence;
    HalTask combatModeDecisionSelector = new HalSelector(combatModeDecisionSelectorItems);

    //////////////////////////////////////////////////////////////////////////////////////////
    // TOP LEVEL /////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////

    HalTask[] btreeItems = new HalTask[2];
    btreeItems[0] = combatModeDecisionSelector;
    btreeItems[1] = oracle;

    behaviorTree = new HalSequence(btreeItems);
  }

  void recalculateNearbyStockpileCells() {
    ArrayList<Building> stockpiles = this.computerState.buildings.get(BuildingCode.STOCKPILE);
    HashSet<Cell> newCellsNearStockpiles = new HashSet<Cell>();

    for (Building stockpile : stockpiles) {
      newCellsNearStockpiles = stockpile.loc.getNearbyGrassCells(DESIRED_FARM_PROXIMITY_TO_STOCKPILE, newCellsNearStockpiles);
    }

    this.grassCellsNearStockpiles.clear();
    this.grassCellsNearStockpiles.addAll(new ArrayList<Cell>(Arrays.asList(newCellsNearStockpiles.toArray(new Cell[newCellsNearStockpiles.size()]))));
  }

  void calculatePotentialBuildingForNewStockpile() {
    ArrayList<Building> sawmillsAndFoundries = new ArrayList<Building>();
    sawmillsAndFoundries.addAll(this.computerState.buildings.get(BuildingCode.SAWMILL));
    sawmillsAndFoundries.addAll(this.computerState.buildings.get(BuildingCode.FOUNDRY));

    for (Building b : sawmillsAndFoundries) {
      for (Building stockpile : this.computerState.buildings.get(BuildingCode.STOCKPILE)) {
        if (stockpile.loc.euclideanDistanceTo(b.loc) <= DESIRED_RESOURCE_BUILDING_PROXIMITY_TO_STOCKPILE) {
          break;
        }
        // this building could use a stockpile nearby
        this.grassCellsNearDesiredBuildingForStockpileProximity.clear();
        HashSet<Cell> cellsNearTargetBuilding = b.loc.getNearbyGrassCells(DESIRED_RESOURCE_BUILDING_PROXIMITY_TO_STOCKPILE - 2);
        this.grassCellsNearDesiredBuildingForStockpileProximity.addAll(new ArrayList<Cell>(Arrays.asList(cellsNearTargetBuilding.toArray(new Cell[cellsNearTargetBuilding.size()]))));
      }
    }

    this.newSawmillOrFoundryBuilt.state = false;
  }

  void behave() {
    System.out.println("---------- Hal Stats ----------");
    System.out.println("Food: " + this.computerState.foodSupply);
    System.out.println("Lumber: " + this.computerState.resourceSupply.get(ResourceCode.LUMBER));
    System.out.println("Metal: " + this.computerState.resourceSupply.get(ResourceCode.METAL));
    System.out.println("-------------------------------");

    // CHEAT: HAL CAN NEVER RUN OUT OF FOOD
    this.computerState.foodSupply = 999;
    if (this.newStockpileBuilt.state) {
      this.recalculateNearbyStockpileCells();
      this.newStockpileBuilt.state = false;
    }

    if (this.newSawmillOrFoundryBuilt.state) {
      this.calculatePotentialBuildingForNewStockpile();
      this.newSawmillOrFoundryBuilt.state = false;
    }

    if (gameState.gameStateIndex > cooldownIndex) {
      if (behaviorTree.execute()) {
        cooldownIndex = gameState.gameStateIndex + ACTION_COOLDOWN;
      }
    }
  }
}


abstract class HalTask {
  abstract boolean execute();
  boolean verbose = true;
}

class AssignCitizen extends HalTask {
  PlayerState state;
  HumanCode type;

  AssignCitizen(PlayerState state, HumanCode type) {
    this.state = state;
    this.type = type;
  }

  boolean execute() {
    Human oldFreeCitizen = this.state.getFreeCitizen();
    if (oldFreeCitizen == null) {
      return false;
    }
    Building targetBuilding = null;
    Human newCitizen = null;

    switch (this.type) {
      case FARMER:
        targetBuilding = this.state.getLeastAssigned(BuildingCode.FARM);
        newCitizen = new Farmer(oldFreeCitizen.loc, targetBuilding, state);
        break;
      case LUMBERJACK:
        targetBuilding = this.state.getLeastAssigned(BuildingCode.SAWMILL);
        newCitizen = new Lumberjack(oldFreeCitizen.loc, targetBuilding, state);
        break;
      case MINER:
        targetBuilding = this.state.getLeastAssigned(BuildingCode.FOUNDRY);
        newCitizen = new Miner(oldFreeCitizen.loc, targetBuilding, state);
        break;
    }

    if (newCitizen == null) {
      return false;
    }

    this.state.removeHuman(oldFreeCitizen);
    this.state.humans.get(this.type).add(newCitizen);
    return true;
  }
}

class CanPlaceX extends HalTask {
  BuildingCode buildingType;
  PlayerState state;

  CanPlaceX(BuildingCode buildingType, PlayerState state) {
    this.buildingType = buildingType;
    this.state = state;
  }

  boolean execute() {
    HashMap<BuildingCode, HashMap<ResourceCode, Integer>> allCosts = this.state.BUILDING_COSTS;
    HashMap<ResourceCode, Integer> buildingCost = allCosts.get(this.buildingType);

    return state.resourceSupply.get(ResourceCode.LUMBER) >= buildingCost.get(ResourceCode.LUMBER) &&
      state.resourceSupply.get(ResourceCode.METAL) >= buildingCost.get(ResourceCode.METAL);
  }
}

class ChangeCombatMode extends HalTask {
  PlayerState state;
  CombatMode mode;

  ChangeCombatMode(PlayerState state, CombatMode mode) {
    this.state = state;
    this.mode = mode;
  }

  boolean execute() {
    this.state.setCombatMode(this.mode);
    return true;
  }
}

class CheckBelowGoldenRatio extends HalTask {
  PlayerState state;
  HumanCode type;
  HashMap<HumanCode, Float> goldenRatio;

  CheckBelowGoldenRatio(PlayerState state, HumanCode type, HashMap<HumanCode, Float> goldenRatio) {
    this.state = state;
    this.type = type;
    this.goldenRatio = goldenRatio;
  }

  boolean execute() {
    float goal = this.goldenRatio.get(this.type);
    float current = (float) this.state.humans.get(this.type).size() / (float) this.state.getAllHumans().size();
    return current < goal;
  }
}

class CheckHaveBuilding extends HalTask {
  PlayerState state;
  BuildingCode type;

  CheckHaveBuilding(PlayerState state, BuildingCode type) {
    this.state = state;
    this.type = type;
  }

  boolean execute() {
    Building targetBuilding = this.state.getLeastAssigned(this.type);
    if (targetBuilding == null || targetBuilding.numFreeAssignments() == 0) {
      return false;
    }
    return true;
  }
}

class EnemyArmyWeak extends HalTask {
  PlayerState state;
  PlayerState humanState;

  EnemyArmyWeak(PlayerState state, PlayerState humanState) {
    this.state = state;
    this.humanState = humanState;
  }

  boolean execute() {
    float humanArmySize = (float) this.humanState.humans.get(HumanCode.SOLDIER).size();
    float myArmySize = (float) this.state.humans.get(HumanCode.SOLDIER).size();

    if (myArmySize == 0) {
      return false;
    }

    return humanArmySize / myArmySize < 0.6;
  }
}

class EnemyTroopsNearby extends HalTask {
  Cell townSquare;
  PlayerState humanState;

  EnemyTroopsNearby(Cell townSquare, PlayerState humanState) {
    this.townSquare = townSquare;
    this.humanState = humanState;
  }

  boolean execute() {
    for (Human soldier : humanState.getSoldiers()) {
      if (soldier.distanceTo(townSquare) < 250) {
        return true;
      }
    }
    return false;
  }
}

class HaveFreeCitizen extends HalTask {
  PlayerState state;

  HaveFreeCitizen(PlayerState state) {
    this.state = state;
  }

  boolean execute() {
    return this.state.humans.get(HumanCode.FREE).size() > 0;
  }
}

class HaveSmallArmy extends HalTask {
  PlayerState state;

  HaveSmallArmy(PlayerState state) {
    this.state = state;
  }

  boolean execute() {
    return this.state.humans.get(HumanCode.SOLDIER).size() < 10;
  }
}

class HaveLargeArmy extends HalTask {
  PlayerState state;

  HaveLargeArmy(PlayerState state) {
    this.state = state;
  }

  boolean execute() {
    return this.state.humans.get(HumanCode.SOLDIER).size() >= 10;
  }
}

class NeedMoreCitizens extends HalTask {
  PlayerState state;

  NeedMoreCitizens(PlayerState state) {
    this.state = state;
  }

  boolean execute() {
    return this.state.getAllHumans().size() >= this.state.populationCapacity && this.state.humans.get(HumanCode.FREE).size() == 0;
  }
}

class PlaceProximityStockpile extends PlaceX {
  PlaceProximityStockpile(BuildingCode buildingType, PlayerState state, PotentialCells potentialCells, CallbackMarker callbackMarker) {
    super(buildingType, state, potentialCells, callbackMarker);
  }

  // if we succeed in placing a proximity stockpile,
  // we want to clear the potential cells because that's
  // our behavior tree's signal that it needs to try to
  // build a proximity stockpile
  boolean execute() {
    boolean result = super.execute();
    if (result) {
      this.potentialCells.primary.clear();
    }
    return result;
  }
}

class PlaceX extends HalTask {
  BuildingCode buildingType;
  PlayerState state;
  PotentialCells potentialCells;
  CallbackMarker callbackMarker;

  PlaceX(BuildingCode buildingType, PlayerState state, PotentialCells potentialCells) {
    this.buildingType = buildingType;
    this.state = state;
    this.potentialCells = potentialCells;
  }

  PlaceX(BuildingCode buildingType, PlayerState state, PotentialCells potentialCells, CallbackMarker callbackMarker) {
    this(buildingType, state, potentialCells);
    this.callbackMarker = callbackMarker;
  }

  boolean execute() {
    Cell potentialCell = potentialCells.get();

    if (potentialCell != null) {
      state.placeBuilding(potentialCell, buildingType);
      if (this.callbackMarker != null) {
        this.callbackMarker.state = true;
      }
      return true;
    }
    return false;
  }
}

class RiskOfStarving extends HalTask {
  PlayerState state;

  RiskOfStarving(PlayerState state) {
    this.state = state;
  }

  boolean execute() {
    int foodNeed = state.getCitizens().size() + (state.getSoldiers().size() * 2);
    if (foodNeed == 0) {
      return false;
    }
    int projection = state.foodSupply / foodNeed;
    return projection < 2;
  }
}

/** Tries children in order until one returns success (return “fail” if all fail) */
class HalSelector extends HalTask {
  HalTask[] children;

  HalSelector(HalTask[] children) {
    this.children = children;
  }

  boolean execute() {
    for (int i = 0; i < children.length; i++) {
      boolean s = children[i].execute();
      if (s) {
        return true;
      }
    }

    return false;
  }
}

/** Tries all its children in turn, returns failure if any fail (or success if all succeed) */
class HalSequence extends HalTask {
  HalTask[] children;

  HalSequence(HalTask[] children) {
    this.children = children;
  }

  boolean execute() {
    for (int i = 0; i < children.length; i++) {
      boolean s = children[i].execute();
      if (!s) {
        return false;
      }
    }
    return true;
  }
}

class CallbackMarker {
  boolean state;
  CallbackMarker() {
    this.state = false;
  }
}

class PotentialCells {
  ArrayList<Cell> primary;
  ArrayList<Cell> secondary;

  PotentialCells(ArrayList<Cell> primary, ArrayList<Cell> secondary) {
    this.primary = primary;
    this.secondary = secondary;
  }

  PotentialCells(ArrayList<Cell> primary) {
    this.primary = primary;
  }

  Cell get() {
    int attempts = 0;

    while(attempts < primary.size()) {
      attempts++;
      Cell potentialCell = primary.get(rng.nextInt(primary.size()));
      if (!potentialCell.hasBuilding()) {
        return potentialCell;
      }
    }

    if (secondary != null) {
      while(attempts < secondary.size()) {
        attempts++;
        Cell potentialCell = secondary.get(rng.nextInt(secondary.size()));
        if (!potentialCell.hasBuilding()) {
          return potentialCell;
        }
      }
    }

    return null;
  }
}