//轨迹类
class Path {
  ArrayList<ArrayList> Paths;
  // ArrayList<PVector> Lines = new ArrayList<PVector>();
  int index = -1; //轨迹总数
  boolean newPath = false;       //新建轨迹开关
  boolean addLoc = false;    //加入坐标开关
  boolean ifMouseMoved =false;
  boolean listen;
  boolean openSound;
  boolean beginRecord = false;
  boolean endRecord = false;
  boolean showAre = true;
  boolean showLine = true;
  boolean showPoint = true;
  int circle_R;
  IntList sureInTrack;
  int[] oscTracks;


  Path() {
    Paths = new ArrayList<ArrayList>();
    circle_R =5;
    //初始化声音

    listen = false;
    openSound = false;
    sureInTrack = new IntList();
  }

  //更新函数
  void recording(PVector loc ) {
    //if(keyPressed){
    if (newPath) {
      //添加轨迹
      //newPath = true;
      //addLoc = true;
      Paths.add(new ArrayList<PVector>());
      //序号递增
      index ++;
      sendTracks();

      newPath = false;
    }
    //开始记录
    //if (addLoc  && Paths!=null && ifMouseMoved) {
    if (addLoc  && Paths!=null ) {
      //for(int i =0; i < Paths.size(); i++)
      //Paths.get(index).add(new PVector(mouseX, mouseY));
      Paths.get(index).add(new PVector(loc.x, loc.y));
    }
    //关闭记录

    if (key=='g') {
      addLoc = false;
    }
    //}
  }

  //发送音轨数量消息
  void sendTracks() {
    OscMessage soundTracks = new OscMessage("soundTracks");

    int a =Paths.size();
    oscTracks = new int[a];
    for (int i =0; i <Paths.size(); i ++ ) {
      oscTracks[i] = i;
    }
    soundTracks.add(oscTracks);
    oscP5.send(soundTracks, stateLocation);
    println("soundTracks: "+soundTracks);
  }

  //绘制音轨
  void drawLine() {
    int line_w = 1;
    color line_color = color(255, 41);
    int alpha_c = 30;
    if (Paths != null) {
      //noFill();
      strokeWeight(line_w);

      if (showLine) {
        for (int i =0; i <Paths.size(); i++) {
          if ( Paths.get(i) != null) {
            beginShape();
            ArrayList<PVector> pos = new ArrayList<PVector>();
            for (int j=0; j < Paths.get(i).size(); j ++) {
              //随机颜色
              randomSeed(i);
              line_color = color(random(i, 255), random(i, 255), random(i, 255));
              //stroke(line_color, alpha_c);
              fill(line_color, alpha_c);

              pos = Paths.get(i);
              vertex(pos.get(j).x, pos.get(j).y);
              ellipse(pos.get(j ).x, pos.get(j).y, circle_R, circle_R);
              //println("drawing", Paths.get(i).size());
            }
            endShape(LINES);
          }

          //绘制触发区域圆
          if (showAre) {
            for (int j=0; j < Paths.get(i).size(); j ++) {
              //随机颜色
              randomSeed(i);
              line_color = color(random(i, 255), random(i, 255), random(i, 255));
              noStroke();
              ArrayList<PVector> pos = new ArrayList<PVector>();
              pos = Paths.get(i);
              fill(line_color, alpha_c);
              ellipse(pos.get(j ).x, pos.get(j).y, 40, 40);
              //println("drawing", Paths.get(i).size());
            }
          }
        }
      }
    }
  }



  //显示所有轨迹
  void run(PVector loc_,PVector currLoc) {
    //if (ifMouseMoved)
    recording(loc_);

    //
    sureInTrack = new IntList();
    drawLine();
    //检查音轨容器中是否有没出发的音轨
    if (Paths != null) {

      for (int i =0; i < Paths.size(); i++) {
        randomSeed(i);
        color C = color(random(i, 255), random(i, 255), random(i, 255));
        check(Paths.get(i), currLoc, C);
        if (listen) {
          sureInTrack.append(i);
        } else {
          //sure.remove(i);
        }
      }

      if (sureInTrack.size() >0) {
        openSound = true;
      } else {
        openSound = false;
      }
    }
    println("sure:  "+sureInTrack);
    ifMouseMoved = false;
  }

  //检查移动点与音轨的距离
  void check(ArrayList<PVector> pos, PVector currenLoc, color c) {
    int yes = 0;
    //color checkColor = color(255, 255, 255);
    color checkColor = c;
    for (PVector p : pos) {
      //PVector N = new PVector(mouseX, mouseY);   //for test
      float d = p.dist(currenLoc);
      //计算点与曲线的最短距离
      fill(checkColor);
      if ( d <= 40) {
        yes+= 1;
        //stroke(255, 0, 0, 10);
        
        if(showPoint)
        ellipse(p.x, p.y, 5, 5);
      }
      if (yes >=1) listen = true;
      if (yes <=0) listen = false;
      //println(listen, yes);
    }
  }
}


//检查鼠标运动
void mouseMoved() {
  paths.ifMouseMoved = true;
}
