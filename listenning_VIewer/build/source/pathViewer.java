import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import netP5.*; 
import oscP5.*; 
import processing.serial.*; 
import java.lang.Math.*; 
import signal.library.*; 
import java.util.Arrays; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class pathViewer extends PApplet {

/*
 # osc 消息
  - sendState
  -
 -----------------
*/








Serial myPort;
Path paths;                       //路径对象
OscP5 oscP5;
SignalFilter myFilter;           //滤波器
NetAddress myRemoteLocation;     //
NetAddress liveAddress;          //ableton Live 的网络地址
PozyxDevice[] pozyxDevices = {};    //Pozyx终端数组

String serialPort = Serial.list()[2];
String  inString;      //String for testing serial communication 串口值

boolean serial = true;          // set to true to use Serial, false to use OSC messages.
boolean testMode = true;        //测试模式
int oscPort = 8888;               // change this to your UDP port Pozyx端口
int     lf = 10;       //ASCII linefeed
float intensity2 = 0.0f;        //强度
int locX, locY;              //从Pozyx取来的坐标原始值
PVector LOC = new PVector(locX, locY);

//滤波参数
float minCutoff = 0.05f;
float beta = 3.0f;
float freq = 120.0f;
float dcutoff = 1.0f;

///////
// some variables for plotting the map 用于绘制地图的一些变量
int offset_x = 30;
int offset_y = 30;
float pixel_per_mm = 0.5f;     //每毫米的像素值？
int border = 500;
int thick_mark = 500;         //边框
int device_size = 15;         //设备数量
int positionHistoryLength = 10;


///////


public void setup() {
  //size(1162, 540);

  
  surface.setResizable(true);
  //stroke(0, 0, 0);
  
  background(255);
  colorMode(RGB, 256);
  /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this, 12000);
  myRemoteLocation = new NetAddress("127.0.0.1", 12001);
  liveAddress = new NetAddress("127.0.0.1", 7400);
  paths = new Path();

  //2d滤波
  cursor(CROSS);
  myFilter = new SignalFilter(this, 3);

  // sets up the input
  if (serial) {
    try {
      myPort = new Serial(this, serialPort, 115200);
      myPort.clear();
      myPort.bufferUntil(lf);
    }
    catch(Exception e) {
      println("Cannot open serial port.");
    }
  } else {
    try {
      oscP5 = new OscP5(this, oscPort);
    }
    catch(Exception e) {
      println("Cannot open UDP port");
    }
  }
}

public void draw() {
  //colorMode(RGB);
  background(0);
  //drawMap();
  myFilter.setFrequency(freq);
  myFilter.setMinCutoff(minCutoff);
  myFilter.setBeta(beta);
  myFilter.setDerivateCutoff(dcutoff);


  //运行模式
  if(!testMode){
      if (pozyxDevices != null) {
       int[] a= pozyxDevices[0].getCurrentPosition();


       calculateAspectRatio();

       PVector mouse = new PVector(mouseX, mouseY);
       PVector value = new PVector(a[0], a[1]);
       //PVector filteredCoord = myFilter.filterCoord2D(filteredLOC(value, 2500), width, height);
       PVector filteredCoord = myFilter.filterCoord2D(value, width, height);
       ellipse(filteredCoord.x, filteredCoord.y, 20, 20);
       pushMatrix();

       translate(offset_x + (border * pixel_per_mm), height - offset_y - (border * pixel_per_mm));
       rotateX(radians(180));
       LOC.set(pixel_per_mm * filteredCoord.x - device_size/2, pixel_per_mm * filteredCoord.y + device_size/2);
       //println(LOC);

       //记录路径并检查触发
       paths.run(mouse, LOC);        //参数一是记录坐标； 参数二是触发坐标
       //ellipse(locX,locY, 10, 10);
       oscSendPosition(LOC);
       fill(255, 0, 0);
       ellipse(pixel_per_mm * filteredCoord.x - device_size/2, pixel_per_mm * filteredCoord.y + device_size/2, device_size, device_size);
       //drawDevices();
       popMatrix();
      }
}

  //调试模式
    if(testMode){
        PVector value = new PVector(mouseX, mouseY);
      //PVector filteredCoord = myFilter.filterCoord2D(filteredLOC(value, 2500), width, height);
      PVector filteredCoord = myFilter.filterCoord2D(value, width, height);
      LOC.set(filteredCoord.x, filteredCoord.y);
      println(LOC);
      //存入坐标，并生成表格
      paths.run(LOC, LOC);
    }


    sendState(playState(paths.sureInTrack, 15));    //发送音轨状态 数组 //<>//

    if(paths.ifRecord){
      oscSendNewTrack();   //发送录制信息
      paths.ifRecord = false;
    }
}

//滤波后坐标信息
public PVector filteredLOC(PVector LOC, int N) {
    PVector filteredValue = LOC;
    int value_X=0;
    int value_Y = 0;
    if (pozyxDevices.length ==5) {
    value_X = pozyxDevices[4].pos_x[0] - pozyxDevices[4].pos_x[5];
    value_Y = pozyxDevices[4].pos_y[0] - pozyxDevices[4].pos_y[5];
    }
    if (abs(value_X) < 3000  && abs(value_Y) < N) {
    return LOC;
    } else {
    return filteredValue;
    }
}

/* incoming osc message are forwarded to the oscEvent method. */
public void oscEvent(OscMessage theOscMessage) {
  /* print the address pattern and the typetag of the received OscMessage */
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());
}


//发送音轨状态
public void sendState(float[] state) {
  OscMessage nullMessage = new OscMessage("state");
  for (int i=0; i < state.length; i++) {
    nullMessage.add(state[i]);
  }
  oscP5.send(nullMessage, myRemoteLocation);
}

//状态数组
public float[] playState(IntList sure, int sum) {

    float[] state = new float[sum];

    for (int i =0; i <state.length; i++) {
    state[i] = 0.0f;
    }


    if (sure != null && paths.openSound) {
    float vol = 1.0f/PApplet.parseFloat(sure.size());
    println(vol);
    for (int i =0; i <sure.size(); i++) {
      state[sure.get(i)] = vol;
    }
    }
    return state;
}


//接受串口信号
public void serialEvent(Serial p) {
  // expected string: POS,network_id,posx,posy,posz
  inString = (myPort.readString());
  print(inString);
  try {
    // parse the data
    String[] dataStrings = split(inString, ',');

    if (dataStrings[0].equals("POS") || dataStrings[0].equals("ANCHOR")) {
      int id = Integer.parseInt(split(dataStrings[1], 'x')[1], 16);
      addPosition(id, PApplet.parseInt(dataStrings[2]), PApplet.parseInt(dataStrings[3]), PApplet.parseInt(dataStrings[4]));
      //将串口数据传给locX,locY
      locX = PApplet.parseInt(map(PApplet.parseInt(dataStrings[2]), 0, 11400, 0, 960));
      locY = PApplet.parseInt(map(PApplet.parseInt(dataStrings[3]), 0, 11400, 0, 540));
    }
  }
  catch (Exception e) {
    println("Error while reading serial data.");
  }
}

//绘制网格
public void drawGrid() {
  float ratio = 5300/11400;
  for ( int i = 0; i < 11400; i += 10) {
  }
}


//Pozyx绘制函数
public void drawMap() {

  int plane_width =  width - 2 * offset_x;
  int plane_height = height - 2 * offset_y;

  // draw the plane
  //stroke(0);
  fill(255);

  rect(offset_x, offset_y, plane_width, plane_height);

  calculateAspectRatio();

  pushMatrix();

  translate(offset_x + (border * pixel_per_mm), height - offset_y - (border * pixel_per_mm));
  rotateX(radians(180));
  fill(0);

  // draw the grid
  strokeWeight(1);
  stroke(200);
  for (int i = 0; i < (int) plane_width/pixel_per_mm/thick_mark; i++)
    line(i * thick_mark * pixel_per_mm, - thick_mark * pixel_per_mm, i * thick_mark * pixel_per_mm, plane_height - thick_mark * pixel_per_mm);

  stroke(100);
  for (int i = 0; i < (int) plane_height/pixel_per_mm/thick_mark - 1; i++)
    line(-(thick_mark * pixel_per_mm), i * thick_mark * pixel_per_mm, plane_width-(thick_mark * pixel_per_mm), (i* thick_mark * pixel_per_mm));

  drawDevices();

  stroke(0);
  fill(0);
  drawArrow(0, 0, 50, 0.f);
  drawArrow(0, 0, 50, 90.f);
  pushMatrix();
  rotateX(radians(180));
  text("X", 55, 5);
  text("Y", -3, -55);
  popMatrix();

  popMatrix();
}

//计算纵横比
public void calculateAspectRatio() {
  float plane_width =  width - 2 * offset_x;
  float plane_height = height - 2 * offset_y;
  int max_width_mm = 0;
  int max_height_mm = 0;
  for (PozyxDevice pozyxDevice : pozyxDevices) {
    int[] pos = pozyxDevice.getCurrentPosition();
    max_width_mm = max(max_width_mm, pos[0]);
    max_height_mm = max(max_height_mm, pos[1]);
  }
  max_width_mm += 2*border;
  max_height_mm += 2*border;
  pixel_per_mm = min(pixel_per_mm, plane_width / max_width_mm, plane_height / max_height_mm);
}


//绘制所有已知设备
public void drawDevices() {
  for (PozyxDevice pozyxDevice : pozyxDevices) {
    drawDevice(pozyxDevice);
  }
}

//绘画坐标函数
public void drawDevice(PozyxDevice device) {
  //stroke(0, 0, 0);
  fill(255);
  int[] current_position = device.getCurrentPosition();
  ellipse(pixel_per_mm * current_position[0] - device_size/2, pixel_per_mm * current_position[1] + device_size/2, device_size, device_size);

  pushMatrix();
  rotateX(radians(180));
  fill(255);
  textSize(11);
  text("0x" + hex(device.ID, 4), pixel_per_mm * current_position[0] - 3 * device_size / 2, - pixel_per_mm * current_position[1] + device_size);
  textSize(12);
  popMatrix();
}

//加入坐标
public void addPosition(int ID, int x, int y, int z) {
  for (PozyxDevice pozyxDevice : pozyxDevices) {
    // ID in device list already
    if (pozyxDevice.ID == ID) {
      pozyxDevice.addPosition(x, y, z);
      return;
    }
  }
  // ID not in device list
  PozyxDevice newPozyx = new PozyxDevice(ID);
  newPozyx.addPosition(x, y, z);
  pozyxDevices = (PozyxDevice[]) append(pozyxDevices, newPozyx);  //扩展device数组
}

public void drawArrow(int center_x, int center_y, int len, float angle) {
  pushMatrix();
  translate(center_x, center_y);
  rotate(radians(angle));
  strokeWeight(2);
  line(0, 0, len, 0);
  line(len, 0, len - 8, -8);
  line(len, 0, len - 8, 8);
  popMatrix();
}


public void oscSendPosition(PVector position) {
  OscMessage myMessage = new OscMessage("/listener");
  float x = map(position.x, 0, width, 0, 1 );
  float y = map(position.y, 0, height, 0, 1 );
  myMessage.add(x);
  myMessage.add(y);
  oscP5.send(myMessage, liveAddress);
  println(myMessage);
}


public void oscSendNewTrack() {
  OscMessage myMessage = new OscMessage("/recording");
  myMessage.add(1);
  oscP5.send(myMessage, myRemoteLocation);
}
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
  boolean ifRecord = false;
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
  public void recording(PVector loc ) {
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
  public void sendTracks() {
    OscMessage soundTracks = new OscMessage("soundTracks");

    int a =Paths.size();
    oscTracks = new int[a];
    for (int i =0; i <Paths.size(); i ++ ) {
      oscTracks[i] = i;
    }
    soundTracks.add(oscTracks);
    oscP5.send(soundTracks, myRemoteLocation);
    println("soundTracks: "+soundTracks);
  }

  //绘制音轨
  public void drawLine() {
    int line_w = 1;
    int line_color = color(255, 80);
    int alpha_c = 120;
    if (Paths != null) {
      noFill();
      strokeWeight(line_w);

      for (int i =0; i <Paths.size(); i++) {
        if ( Paths.get(i) != null) {
          noFill();
          beginShape();
          for (int j=0; j < Paths.get(i).size(); j ++) {
            //随机颜色
            randomSeed(i);
            line_color = color(random(i, 255), random(i, 255), random(i, 255));
            //stroke(line_color, alpha_c);
            ArrayList<PVector> pos = new ArrayList<PVector>();
            pos = Paths.get(i);
            vertex(pos.get(j).x, pos.get(j).y);
            ellipse(pos.get(j ).x, pos.get(j).y, circle_R, circle_R);
            //println("drawing", Paths.get(i).size());
          }
          endShape(LINES);

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



  //显示所有轨迹
  public void run(PVector loc_, PVector currLoc) {
    //if (ifMouseMoved)
    recording(loc_);

    //
    sureInTrack = new IntList();
    drawLine();
    //检查音轨容器中是否有没出发的音轨
    if (Paths != null) {

      for (int i =0; i < Paths.size(); i++) {
        check(Paths.get(i), currLoc);
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
  public void check(ArrayList<PVector> pos, PVector currenLoc) {
    int yes = 0;
    int checkColor = color(255, 255, 255);
    for (PVector p : pos) {
      //PVector N = new PVector(mouseX, mouseY);   //for test
      float d = p.dist(currenLoc);
      //计算点与曲线的最短距离
      fill(checkColor, 210);
      if ( d <= 40) {
        yes+= 1;
        //stroke(255, 0, 0, 10);
        ellipse(p.x, p.y, 5, 5);
      }
      if (yes >=1) listen = true;
      if (yes <=0) listen = false;
      //println(listen, yes);
    }
  }
}

//存入开关
public void keyPressed() {
  if (key=='k') {
    paths.newPath = true;
    paths.addLoc = true;
    paths.ifRecord = true;
  }

  if (key=='g') {
    paths.ifRecord = true;
    paths.addLoc = false;
  }
}

//检查鼠标运动
public void mouseMoved() {
  paths.ifMouseMoved = true;
}

class PozyxDevice{
  private int ID;
  private int[] pos_x = new int [positionHistoryLength];
  private int[] pos_y = new int [positionHistoryLength];
  private int[] pos_z = new int [positionHistoryLength];
  
  public PozyxDevice(int ID){this.ID = ID;}
  
  public void addPosition(int x, int y, int z){
    System.arraycopy(pos_x, 0, pos_x, 1, positionHistoryLength - 1);
    System.arraycopy(pos_y, 0, pos_y, 1, positionHistoryLength - 1);
    System.arraycopy(pos_z, 0, pos_z, 1, positionHistoryLength - 1);
    
    pos_x[0] = x;
    pos_y[0] = y;
    pos_z[0] = z;
  }
  
  public int[] getCurrentPosition(){
    int[] position ={pos_x[0], pos_y[0], pos_z[0]};
    return position;
  }
}
  public void settings() {  size(1000, 700, P3D);  pixelDensity(2); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "pathViewer" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
