class Citizen extends Human {
  final int CARRY_CAPACITY = 10;

  boolean isCarryingSupply;
  int carryWeight;

  Citizen(Cell initialLocation, Building buildingAssignment, PlayerState ownerState) {
    super(initialLocation, buildingAssignment, ownerState);
    this.carryWeight = 0;
  }

  void setCarryWeight(int c) {
    this.carryWeight = c;
  }

  boolean isFree() {
    return false;
  }
}
