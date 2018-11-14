class CheckAnnulus {
  PVector audience = new PVector();    //检测对象向量
  boolean testMode = false;
  float theDists = 0;

  CheckAnnulus() {
  }

  void setMover(PVector audience_) {
    audience = audience_;
  }

  void drawAnnulus(String name, PVector center, float w, float h, float annuW, color c1, color bg) {
    /*根据椭圆公式：
     x = h + a*cos(t);
     y = k + b*sin(t);
     参数
     @环形中心坐标： center;
     @环形宽和高： w， h；
     @环形环宽； annuW;
     @颜色
     */

    //存档
    ArrayList<PVector> ellipsePOS = new ArrayList<PVector>();

    float x, y;  //椭圆坐标
    strokeWeight(2);
    stroke(80, 120);
    //存入坐标
    beginShape();
    for (float i = -PI; i <= PI; i += 0.01) {
      x= center.x + w * cos(i);
      y = center.y + h * sin(i);
      if (testMode) {
        vertex(x, y);
      }
      PVector pos = new PVector(x, y);
      ellipsePOS.add(pos);
    }
    endShape(LINES);


    //绘制
    //外环
    if (check(ellipsePOS, annuW)) {
      fill(c1);
      float vol = map(theDists, 0, annuW*0.5, 1, 0);
      sendOSC(name, vol);
      println(name, vol);
      sendWhichSpace(name, name);
    } else {
      fill(bg);
      sendOSC(name, 0);
      //sendWhichSpace(name, "empty");
    }

    beginShape();
    for (float i = -PI; i <= PI; i += 0.01) {
      float x_out, y_out;
      x_out= center.x + (w+annuW*0.5) * cos(i);
      y_out = center.y + ( h+annuW*0.5 )* sin(i);
      vertex(x_out, y_out);
    }
    endShape(LINES);

    //绘制内环
    fill(bg);
    beginShape();
    for (float i = -PI; i <= PI; i += 0.01) {
      float x_in, y_in;
      x_in= center.x + (w-annuW*0.5) * cos(i);
      y_in = center.y + (h-annuW*0.5) * sin(i);
      vertex(x_in, y_in);
    }
    endShape(LINES);
  }


  boolean check(ArrayList<PVector> pos, float annuW_) {
    //ArrayList<FloatList> DISTS = new ArrayList<FloatList>();
    boolean inside = false;
    FloatList DISTS = new FloatList();

    //计算距离
    for (int i =0; i < pos.size(); i ++) {
      //ArrayList<PVector> thisAnnulus = new ArrayList<PVector>();
      //thisAnnulus = ANNULUS.get(i);
      float dist = pos.get(i).dist(audience);
      DISTS.append(dist);
    }

    theDists = DISTS.min();
    //计算最小值
    if (theDists < annuW_*0.5) {
      inside = true;
    }
    return inside;
  }



  void sendOSC(String name, float msg) {
    OscMessage checkIn = new OscMessage(name);
    checkIn.add(msg);
    oscP5.send(checkIn, myRemoteLocation);
  }   
  void sendWhichSpace(String name, String msg) {
    OscMessage checkIn = new OscMessage(name);
    checkIn.add(msg);
    oscP5.send(checkIn, reverbLocation);
  }
}
