abstract class Human extends WorldlyObject {
  HumanCode type;
  float TARGET_RADIUS = 2;
  float SLOW_RADIUS = 5;
  float MAX_SPEED = 0.1;
  float MAX_ACCELERATION = 0.01;
  float MAX_HEALTH = 250;
  float STARVE_DAMAGE = 25;

  int[] c = new int[3];
  float health;
  PlayerState ownerState;
  Building assignedBuilding;
  Blackboard blackboard;
  Task btree;

  Human(Cell initialLocation, Building buildingAssignment, PlayerState ownerState) {
    super(initialLocation);
    this.w = this.h = 4;
    this.c = new int[]{20, 20, 20};
    this.health = MAX_HEALTH;
    this.assignedBuilding = buildingAssignment;
    buildingAssignment.addAssignee(this);
    this.ownerState = ownerState;

    this.blackboard = new Blackboard();
    this.blackboard.put("Human", this);
    this.btree = new Wander(this.blackboard, 25);
  }

  void unassignFromBuilding() {
    this.assignedBuilding.removeAssignee(this);
    this.assignedBuilding = null;
  }

  void assignToNewBuilding(Building newAssignment) {
    this.assignedBuilding.removeAssignee(this);
    this.assignedBuilding = newAssignment;
    newAssignment.addAssignee(this);
  }

  void draw() {
    this.btree.execute();

    noStroke();
    fill(c[0], c[1], c[2]);
    ellipse(this.pos.x, this.pos.y, this.w, this.w);

    if (this.health < MAX_HEALTH) {
      fill(255, 0, 0);
      rect(this.pos.x - 4, this.pos.y - 4, 8, 2);
      fill(0, 255, 0);
      rect(this.pos.x - 4, this.pos.y - 4, 8 * (this.health / MAX_HEALTH), 2);
    }
  }

  void behave() {
    this.btree.execute();
  }

  void moveTo(float x, float y) {
    // Get the direction and distance to the target
    PVector target = new PVector(x, y);
    PVector direction = target.sub(pos);
    float distance = direction.mag();

    // Check if we are there, no steering
    if (distance < TARGET_RADIUS) {
      return;
    }

    // If we are outside SLOW_RADIUS, go max speed
    float targetSpeed = 0;
    if (distance > SLOW_RADIUS) {
      targetSpeed = MAX_SPEED;
    } else {  // calculate a scaled speed
      targetSpeed = MAX_SPEED * distance / SLOW_RADIUS;
    }

    // Velocity combines speed and direction
    PVector targetVelocity = direction;
    targetVelocity.normalize();
    targetVelocity.mult(targetSpeed);

    // Acceleration tries to get to the target velocity
    PVector acceleration = targetVelocity.sub(this.vel);

    // Check if the acceleration is too fast
    if (acceleration.mag() > MAX_ACCELERATION) {
      acceleration.normalize();
      acceleration.mult(MAX_ACCELERATION);
    }

    // Calculate new position
    PVector pos = this.pos.copy();
    PVector ray = this.vel.copy();
    ray.setMag(CELL_SIZE/2);

    pos.add(ray);
    Cell c = boardMap.cellAtPos(pos);
    if(c.hasImpass(assignedBuilding)){
      ray.rotate(PI/2 + random(-PI/16,PI/16));
      ray.setMag(.2);
      this.vel.add(ray);
    }


    // Calculate new character velocity
    this.vel.add(acceleration);

    // Move the character
    this.pos.add(this.vel);

    // Update this character's cell location
    this.loc = boardMap.cellAtPos(this.pos);

  }

  void starve() {
    this.health -= this.STARVE_DAMAGE;
  }
}

enum HumanCode {
  FARMER, LUMBERJACK, MINER, SOLDIER, FREE;

  @Override
  public String toString() {
      return name().toLowerCase();
  }
}
