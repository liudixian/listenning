class Viewer{
    float r1, r2, r3;
    PVector audience = new PVector();
    
    //触发参数
    boolean ifRed= false;
    boolean ifGreen= false;
    boolean ifBlue= false;
    boolean testVersion = false;
    //颜色
    color RED = color(214, 1, 56,18);
    color GREEN = color(134, 249, 210,18);
    color BLUE = color(5, 64, 255,18);
    //mouse:移动物到中心的距离；  dist1/2/3 分别mouse到触发圆的距离
    float mouse, dist1, dist2, dist3;
    int bicycleWidth = 75;    //bicycle触发的宽度
    int bigSpaceWidth = 75;   //同上
    float beeWidth = r3;

    Viewer(PVector ad, float R1, float R2, float R3 ){
        r1 = R1;
        r2 = R2;
        r3 = R3;
        audience = ad;
    }

    void showWhat() {
      if (dist1 <= bicycleWidth/2) {
        stater("bicycle");
        //println("bicycle");
      }

      if (dist2 <= bigSpaceWidth/2) {
        stater("bigSpace");
      }

      if (dist3 <= r3) {
        stater("bee");
      }
    }

    void drawSoundMap() {
      color backgrounColor = color(10, 17, 58);
      color strokeColor = color(255, 6);
      strokeWeight(2);

      showWhat();
      pushMatrix();
      noFill();
      translate(width*0.5, height*0.5);
      if (testVersion) {
        ellipse(0, 0, r1*2-bicycleWidth, r1*2-bicycleWidth);
        ellipse(0, 0, r2*2-bigSpaceWidth, r2*2-bigSpaceWidth);
        line(0, 0, audience.x-width*0.5, audience.y-height*0.5);
      }
      stroke(strokeColor);
      ellipse(0, 0, r1*2, r1*2);
      ellipse(0, 0, r2*2, r2*2);
      ellipse(0, 0, r3*2, r3*2);

      if (ifRed) {

        stroke(strokeColor);
        fill(RED);
        ellipse(0, 0, r1*2, r1*2);
        fill(backgrounColor);
        ellipse(0, 0, r2*2, r2*2);
        ellipse(0, 0, r3*2, r3*2);
      }

      if (ifGreen) {
        stroke(strokeColor);
        fill(GREEN);
        ellipse(0, 0, r2*2, r2*2);
        fill(backgrounColor);
        ellipse(0, 0, r3*2, r3*2);
      }
      if (ifBlue) {
        stroke(strokeColor);
        fill(BLUE);
        ellipse(0, 0, r3*2, r3*2);
      }
      popMatrix();
    }

    void stater(String state) {
      if (state == "bicycle") {
        ifRed =true;
        ifGreen = false;
        ifBlue = false;
      }

      if (state == "bigSpace") {
        ifRed = false;
        ifGreen = true;
        ifBlue = false;
      }

      if (state == "bee") {
        ifRed =false;
        ifGreen = false;
        ifBlue = true;
      }
    }


    void update(){
        audience.set(mouseX, mouseY);
        mouse = dist(audience.x, audience.y, width*0.5, height*0.5);
        dist1 = abs(mouse-(r2+bicycleWidth/2));
        dist2 = abs(mouse-(r3+bigSpaceWidth/2));
        dist3 = abs(mouse);

        ifRed =false;
        ifGreen = false;
        ifBlue = false;
    }

}
