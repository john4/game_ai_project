class Stockpile extends Building {
  PImage img;

  Stockpile(Cell initialLocation) {
    super(initialLocation, "Stockpile");
    this.img = loadImage("crate.png");
    this.impassable = false;
  }

  void draw() {
    image(this.img, this.loc.x + 1, this.loc.y + 1);
  }
}
