//<>// //<>// //<>// //<>// //<>// //<>// //<>//
/*
 # osc 消息
 - sendState
 -
 -----------------
 显示模式
 - "S_SCAPE_MODE"
 - "S_TRACK_MODE"
 - "Default_MODE"
 */

import netP5.*;
import oscP5.*;
import processing.serial.*;
import java.lang.Math.*;
import signal.library.*;
import java.util.Arrays;
import controlP5.*;


Serial myPort;
Path paths;                       //路径对象
OscP5 oscP5;
SignalFilter myFilter;           //滤波器
NetAddress myRemoteLocation;     //
NetAddress recordingLocation;     //
NetAddress reverbLocation;     //
NetAddress stateLocation;     //
NetAddress liveAddress;          //ableton Live 的网络地址
PozyxDevice[] pozyxDevices = {};    //Pozyx终端数组
//Viewer v;
CheckAnnulus c;
ControlP5 cp5;
Accordion accordion;
Table presetTable;
Table presetCOPY ;

String serialPort = Serial.list()[2];
String  inString;      //String for testing serial communication 串口值

boolean serial = true;          // set to true to use Serial, false to use OSC messages.
boolean testMode = false;        //测试模式
boolean showScape = true;
boolean showTracks = false;
String dspMode =  "Default_MODE";
boolean mouseTest = false;
int oscPort = 8888;               // change this to your UDP port Pozyx端口
int     lf = 10;       //ASCII linefeed
float intensity2 = 0.0;        //强度
int locX, locY;              //从Pozyx取来的坐标原始值
PVector LOC = new PVector(locX, locY);

//滤波参数
float minCutoff = 0.05;
float beta = 3.0;
float freq = 120.0;
float dcutoff = 1.0;

///////
// some variables for plotting the map 用于绘制地图的一些变量
int offset_x = 30;
int offset_y = 30;
float pixel_per_mm = 0.5;     //每毫米的像素值？
int border = 500;
int thick_mark = 500;         //边框
int device_size = 15;         //设备数量
int positionHistoryLength = 10;
PVector center;

//drawAnnulus
float Anu_1_a ;
float Anu_1_b ;
float Anu_1_w ;
int Anu_1_oX;
int Anu_1_oY;
float Anu_2_a ;
float Anu_2_b ;
float Anu_2_w ;
int Anu_2_oX;
int Anu_2_oY;
color c1 = color(0, 20, 80, 150);
color c2 = color(80, 20, 10, 150);
color bg = color(10, 17, 58, 150);


//传给controller的默认值
float a_1_Default = 192.0;
float b_1_Default = 184.0;
float w_1_Defaulte = 84;
int oX_Default_1 = 440;
int oY_Default_1 = 205;
float a_2_Default = 164.0;
float b_2_Default = 120.0;
float w_2_Defaulte = 116;
int oX_Default_2 = 453;
int oY_Default_2 = 205;
color C_Default_1 = color(0, 20, 80, 150);
color C_Default_2 = color(80, 20, 10, 150);

void setup() {
  //size(1162, 540);

  size(1000, 700, P3D);
  surface.setResizable(true);
  pixelDensity(2);
  smooth();
  background(255);
  colorMode(RGB, 256);

  /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this, 12000);
  myRemoteLocation = new NetAddress("127.0.0.1", 12003);
  recordingLocation = new NetAddress("127.0.0.1", 12002);
  stateLocation = new NetAddress("127.0.0.1", 12004);
  liveAddress = new NetAddress("127.0.0.1", 7400);
  reverbLocation = new NetAddress("127.0.0.1", 12010);

  //初始化path对象
  paths = new Path();


  c = new CheckAnnulus();

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



  //将储存预设值输入controller默认值列表
  //presetCOPY = loadTable("preset.csv", "header");

  //a_1_Default = presetCOPY.getFloat(0, "半轴a");
  //b_1_Default = presetCOPY.getFloat(0, "半轴b");
  //w_1_Defaulte = presetCOPY.getFloat(0, "环宽");
  //oX_Default_1 = presetCOPY.getInt(0, "x");
  //oY_Default_1 = presetCOPY.getInt(0, "y");
  //a_2_Default = presetCOPY.getFloat(1, "半轴a");
  //b_2_Default = presetCOPY.getFloat(1, "半轴b");
  //w_2_Defaulte = presetCOPY.getFloat(1, "环宽");
  //oX_Default_2 = presetCOPY.getInt(1, "x");
  //oY_Default_2 = presetCOPY.getInt(1, "y");
  //C_Default_1 = color(0, 20, 80, 150);
  //C_Default_2 = color(80, 20, 10, 150);

  //GUI
  gui();
}

void draw() {
  //GUI调参
  Anu_1_a = cp5.getController("a-1").getValue();
  Anu_1_b = cp5.getController("b-1").getValue();
  Anu_1_w = cp5.getController("w-1").getValue();
  Anu_1_oX = (int)cp5.getController("x-1").getValue();
  Anu_1_oY = (int)cp5.getController("y-1").getValue();
  Anu_2_a = cp5.getController("a-2").getValue();
  Anu_2_b = cp5.getController("b-2").getValue();
  Anu_2_w = cp5.getController("w-2").getValue();
  Anu_2_oX =(int)cp5.getController("x-2").getValue();
  Anu_2_oY =(int)cp5.getController("y-2").getValue();

  //println(Anu_1_oX, cp5.getController("x-1").getValue() );
  /////

  //colorMode(RGB);
  background(10, 17, 58);

  //drawMap();
  myFilter.setFrequency(freq);
  myFilter.setMinCutoff(minCutoff);
  myFilter.setBeta(beta);
  myFilter.setDerivateCutoff(dcutoff);

  //显示模式
  DSP_Modes(dspMode);
  //DSP_Modes("S_TRACK_MODE");
  //DSP_Modes("S_SCAPE_MODE");

  if (showTracks) {
    paths.showAre = false;
    paths.showLine = true;
    paths.showPoint = true;
  }
  //v.RED = color(214, 1, 56,18);
  //v.GREEN = color(134, 249, 210,18);
  //v.BLUE = color(5, 64, 255,18);

  //////////////////////------运行模式--------////////////////////////////////
  if (!testMode) {
    if (pozyxDevices.length >4) {


      int[] a= pozyxDevices[0].getCurrentPosition();
      int[] A1= pozyxDevices[1].getCurrentPosition();
      int[] A2= pozyxDevices[2].getCurrentPosition();
      int[] A3= pozyxDevices[3].getCurrentPosition();
      int[] A4= pozyxDevices[4].getCurrentPosition();


      calculateAspectRatio();

      PVector mouse = new PVector(mouseX, mouseY);
      PVector value = new PVector(a[0], a[1]);
      //PVector filteredCoord = myFilter.filterCoord2D(filteredLOC(value, 2500), width, height);
      PVector filteredCoord = myFilter.filterCoord2D(value, width, height);
      ellipse(filteredCoord.x, filteredCoord.y, 20, 20);

      
      pushMatrix();

      translate(offset_x + (border * pixel_per_mm), height - offset_y - (border * pixel_per_mm));
      rotateX(radians(180));
      //fill(210);
      ellipse(mouse.x -offset_x*2, height-mouse.y-offset_y*2,25,25);
      PVector mouseForTest = new PVector(mouse.x -offset_x*2, height-mouse.y-offset_y*2);
      
      LOC.set(pixel_per_mm * filteredCoord.x - device_size/2, pixel_per_mm * filteredCoord.y + device_size/2);
      //println(LOC);

      //draw soundScapeMap
      if (showScape) {

        //c.setMover(new PVector(mouseX, mouseY));
        if (mouseTest) {
          c.setMover(mouseForTest);
        } else {
          c.setMover(LOC);
        }
        // c.drawAnnulus("bicycle", new PVector(Anu_1_oX,Anu_1_oY), 180.0, 440.0, 75, c1, bg);
        // c.drawAnnulus("bigspace", new PVector(Anu_2_oX,Anu_2_oY), 60, 200, 35, c2, bg);

        center = new PVector(pixel_per_mm *(A1[0] - A2[0])*0.5 - device_size/2
          , pixel_per_mm * (A1[1] - A3[1])*0.5 + device_size/2);
        //A1右上角 0，0
        PVector right_UP = new PVector(pixel_per_mm * A1[0] - device_size/2
          , pixel_per_mm * (A1[1]) + device_size/2);
        //A2 左上角
        PVector left_UP = new PVector(pixel_per_mm * A2[0] - device_size/2
          , pixel_per_mm * (A2[1]) + device_size/2);
        //A4右下角   
        PVector right_DOWN = new PVector(pixel_per_mm *(A4[0]) - device_size/2
          , pixel_per_mm * (A4[1]) + device_size/2);
        //A4左下角  
        PVector left_DOWN = new PVector(pixel_per_mm * A3[0] - device_size/2
          , pixel_per_mm * (A3[1])*0.5 + device_size/2);
        //ellipse(pixel_per_mm * current_position[0] - device_size/2, pixel_per_mm * current_position[1] + device_size/2, device_size, device_size);

        //中间
        c.drawAnnulus("speed", new PVector(center.x*0.5, center.y), 200, 176, 66, c1, bg);   
        c.drawAnnulus("church", new PVector(center.x*0.5, center.y), 96, 88, 80, c2, bg);
        c.drawAnnulus("toilet", new PVector(center.x*0.5, center.y), 0, 0, 70, c2, bg);
        //中侧面
        //c.drawAnnulus("clock", new PVector(center.x*1.5, center.y), 20, 20, 20, c1, bg);   
        //左下角
        c.drawAnnulus("train", left_DOWN, 28, 28, 70, c2, bg);
        //右下角
        c.drawAnnulus("factory", new PVector(center.x, left_DOWN.y), 28, 28, 70, c2, bg);
        //右上
        c.drawAnnulus("airplan", new PVector(center.x, left_UP.y), 28, 28, 70, c2, bg);
        //左上
        c.drawAnnulus("sea", left_UP, 28, 28, 70, c2, bg);

        //noFill();
        stroke(255,30);
        beginShape();
        vertex(center.x, right_UP.y);
        vertex(center.x, right_DOWN.y);
        vertex(left_DOWN.x, left_DOWN.y);
        vertex(left_UP.x, left_UP.y);
        vertex(center.x, right_UP.y);
        endShape();
      }

      //记录路径并检查触发
      noStroke();
      if (mouseTest) {
        paths.run(mouseForTest, mouseForTest);        //参数一是记录坐标； 参数二是触发坐标
      } else {
        paths.run(LOC, LOC);        //参数一是记录坐标； 参数二是触发坐标
      }
      //ellipse(locX,locY, 10, 10);
      oscSendPosition(LOC);
      fill(255, 0, 0);
      ellipse(pixel_per_mm * filteredCoord.x - device_size/2, pixel_per_mm * filteredCoord.y + device_size/2, device_size, device_size);
      drawDevices();
      //监视方框
      //rectMode(CENTER);
      //fill(255, 0);
      //stroke(255, 120);
      //rect(center.x, center.y, 873, 412);

      popMatrix();
    }
  }

  //////////////////////------调试模式--------////////////////////////////////

  //调试模式
  if (testMode) {
    if (showScape) {

      c.setMover(new PVector(mouseX, mouseY));
      c.drawAnnulus("bicycle", new PVector(Anu_1_oX, Anu_1_oY), Anu_1_a, Anu_1_b, Anu_1_w, c1, bg);
      c.drawAnnulus("bigspace", new PVector(Anu_2_oX, Anu_2_oY), Anu_2_a, Anu_2_b, Anu_2_w, c2, bg);
    }

    noStroke();
    PVector value = new PVector(mouseX, mouseY);
    //PVector filteredCoord = myFilter.filterCoord2D(filteredLOC(value, 2500), width, height);
    PVector filteredCoord = myFilter.filterCoord2D(value, width, height);
    LOC.set(filteredCoord.x, filteredCoord.y);
    //println(LOC);
    //存入坐标，并生成表格
    paths.run(LOC, LOC);
  }


  sendState(playState(paths.sureInTrack, 15));    //发送音轨状态 数组

  if (paths.beginRecord) {
    oscSendNewTrack(1);   //发送录制信息
    paths.beginRecord = false;
  }
  if (paths.endRecord) {
    oscSendNewTrack(0);   //发送录制信息
    paths.endRecord = false;
  }
}

//滤波后坐标信息
PVector filteredLOC(PVector LOC, int N) {
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
void oscEvent(OscMessage theOscMessage) {
  /* print the address pattern and the typetag of the received OscMessage */
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());
}


//发送音轨状态
void sendState(float[] state) {
  OscMessage nullMessage = new OscMessage("state");
  for (int i=0; i < state.length; i++) {
    nullMessage.add(state[i]);
  }
  oscP5.send(nullMessage, stateLocation);
}

//状态数组
float[] playState(IntList sure, int sum) {

  float[] state = new float[sum];

  for (int i =0; i <state.length; i++) {
    state[i] = 0.0;
  }


  if (sure != null && paths.openSound) {
    float vol = 1.0/float(sure.size());
    //println(vol);
    for (int i =0; i <sure.size(); i++) {
      state[sure.get(i)] = vol;
    }
  }
  return state;
}


//接受串口信号
void serialEvent(Serial p) {
  // expected string: POS,network_id,posx,posy,posz
  inString = (myPort.readString());
  print(inString);
  try {
    // parse the data
    String[] dataStrings = split(inString, ',');

    if (dataStrings[0].equals("POS") || dataStrings[0].equals("ANCHOR")) {
      int id = Integer.parseInt(split(dataStrings[1], 'x')[1], 16);
      addPosition(id, int(dataStrings[2]), int(dataStrings[3]), int(dataStrings[4]));
      //将串口数据传给locX,locY
      locX = int(map(int(dataStrings[2]), 0, 11400, 0, 960));
      locY = int(map(int(dataStrings[3]), 0, 11400, 0, 540));
    }
  }
  catch (Exception e) {
    println("Error while reading serial data.");
  }
}

//绘制网格
void drawGrid() {
  float ratio = 5300/11400;
  for ( int i = 0; i < 11400; i += 10) {
  }
}


//Pozyx绘制函数
void drawMap() {

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
  drawArrow(0, 0, 50, 0.);
  drawArrow(0, 0, 50, 90.);
  pushMatrix();
  rotateX(radians(180));
  text("X", 55, 5);
  text("Y", -3, -55);
  popMatrix();

  popMatrix();
}

//计算纵横比
void calculateAspectRatio() {
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
void drawDevices() {
  //for (PozyxDevice pozyxDevice : pozyxDevices) {
  //  drawDevice(pozyxDevice);
  //}

  for (int i =2; i <pozyxDevices.length; i ++) {
    drawDevice(pozyxDevices[i]);
  }
}

//绘画坐标函数
void drawDevice(PozyxDevice device) {
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
void addPosition(int ID, int x, int y, int z) {
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

void drawArrow(int center_x, int center_y, int len, float angle) {
  pushMatrix();
  translate(center_x, center_y);
  rotate(radians(angle));
  strokeWeight(2);
  line(0, 0, len, 0);
  line(len, 0, len - 8, -8);
  line(len, 0, len - 8, 8);
  popMatrix();
}


void oscSendPosition(PVector position) {
  OscMessage myMessage = new OscMessage("/listener");
  float x = map(position.x, 0, width, 0, 1 );
  float y = map(position.y, 0, height, 0, 1 );
  myMessage.add(x);
  myMessage.add(y);
  oscP5.send(myMessage, liveAddress);
  //println(myMessage);
}


void oscSendNewTrack(int a) {
  OscMessage myMessage = new OscMessage("/recording");
  myMessage.add(a);
  oscP5.send(myMessage, recordingLocation);
}


void DSP_Modes(String modes) {
  if (modes == "S_SCAPE_MODE") {
    showTracks = false;
    showScape = true;
  }

  if (modes =="S_TRACK_MODE") {
    showTracks = true;
    showScape = false;
  }

  if (modes == "Default_MODE") {
    showTracks = true;
    showScape = true;
  }
}


//////////////-----------GUI CODE-------------////////////////

void gui() {
  cp5 = new ControlP5(this);

  int sliderH = 10;
  int sliderW = 150;
  int interval = 5;
  float MAX = 600.0;
  float MIN = 0.0;
  float w_MAX = 300;
  float Default = 200.0;


  cp5 = new ControlP5(this);

  Group g1 = cp5.addGroup("AnnulusSize")
    .setBackgroundColor(color(255, 0))
    .setBackgroundHeight(150)
    ;

  cp5.addSlider("a-1")
    .setPosition(0, interval)
    .setSize(sliderW, sliderH)
    .setRange(MIN, MAX)
    .setValue(a_1_Default)
    .moveTo(g1)
    ;

  cp5.addSlider("b-1")
    .setPosition(0.0, interval+(sliderH+interval))
    .setSize(sliderW, sliderH)
    .setRange(MIN, MAX)
    .setValue(b_1_Default)
    .moveTo(g1)
    ;
  cp5.addSlider("w-1")
    .setPosition(0.0, interval+(sliderH+interval)*2)
    .setSize(sliderW, sliderH)
    .setRange(MIN, w_MAX)
    .setValue(w_1_Defaulte)
    .moveTo(g1)
    ;

  //中心坐标
  cp5.addSlider("x-1")
    .setPosition(0.0, interval+(sliderH+interval)*3)
    .setSize(sliderW, sliderH)
    .setRange(0, width)
    .setValue(oX_Default_1)
    .moveTo(g1)
    ;
  cp5.addSlider("y-1")
    .setPosition(0.0, interval+(sliderH+interval)*4)
    .setSize(sliderW, sliderH)
    .setRange(0, height)
    .setValue(oY_Default_1)
    .moveTo(g1)
    ;

  //环2参数
  cp5.addSlider("a-2")
    .setPosition(0.0, interval+(sliderH+interval)*5)
    .setSize(sliderW, sliderH)
    .setRange(MIN, MAX)
    .setValue(a_2_Default)
    .moveTo(g1)
    ;

  cp5.addSlider("b-2")
    .setPosition(0.0, interval+(sliderH+interval)*6)
    .setSize(sliderW, sliderH)
    .setRange(MIN, MAX)
    .setValue(b_2_Default)
    .moveTo(g1)
    ;
  cp5.addSlider("w-2")
    .setPosition(0.0, interval+(sliderH+interval)*7)
    .setSize(sliderW, sliderH)
    .setRange(MIN, w_MAX)
    .setValue(w_2_Defaulte)
    .moveTo(g1)
    ;

  //中心坐标
  cp5.addSlider("x-2")
    .setPosition(0, interval+(sliderH+interval)*8)
    .setSize(sliderW, sliderH)
    .setRange(0, width)
    .setValue(oX_Default_2)
    .moveTo(g1)
    ;
  cp5.addSlider("y-2")
    .setPosition(0, (int)(interval+(sliderH+interval)*9))
    .setSize(sliderW, sliderH)
    .setRange(0, height)
    .setValue(oY_Default_2)
    .moveTo(g1)
    ;

  cp5.addBang("savetoDefault")
    .setPosition(0, interval+(sliderH+interval)*10)
    .setSize(20, 20)
    .moveTo(g1)
    .plugTo(this, "savetoDefault");
  ;

  Group g2 = cp5.addGroup("AnnulusColor")
    .setBackgroundColor(color(255, 0))
    .setBackgroundHeight(150)
    ;

  //统一设定坐标
  accordion = cp5.addAccordion("acc")
    .setPosition(20, 20)
    //.setWidth(200)
    .setSize(180, 100)
    .addItem(g1)
    //.addItem(g2)
    //.addItem(g3)
    ;
}

void savetoDefault() {
  a_1_Default = cp5.getController("a-1").getValue();
  b_1_Default = cp5.getController("b-1").getValue();
  w_1_Defaulte = cp5.getController("w-1").getValue();
  oX_Default_1 = (int)cp5.getController("x-1").getValue();
  oY_Default_1 = (int)cp5.getController("y-1").getValue();
  a_2_Default = cp5.getController("a-2").getValue();
  b_2_Default = cp5.getController("b-2").getValue();
  w_2_Defaulte = cp5.getController("w-2").getValue();
  oX_Default_1 = (int)cp5.getController("x-2").getValue();
  oY_Default_1 = (int)cp5.getController("y-2").getValue();

  //预设
  presetTable = new Table();
  color c = color(1, 10, 20);
  presetTable.addColumn("id");   //加入列
  presetTable.addColumn("半轴a");  //加入第一列主题
  presetTable.addColumn("半轴b");
  presetTable.addColumn("环宽");
  presetTable.addColumn("x");
  presetTable.addColumn("y");
  presetTable.addColumn("颜色");

  //环1
  TableRow Annu_1 = presetTable.addRow();
  Annu_1.setFloat("半轴a", a_1_Default);
  Annu_1.setFloat("半轴b", b_1_Default);
  Annu_1.setFloat("x", oX_Default_1);
  Annu_1.setFloat("y", oY_Default_1);
  Annu_1.setInt( "颜色", C_Default_1);
  //环2
  TableRow Annu_2 = presetTable.addRow();
  Annu_2.setFloat("半轴a", a_2_Default);
  Annu_2.setFloat("半轴b", b_2_Default);
  Annu_2.setFloat( "环宽", w_2_Defaulte);
  Annu_2.setFloat( "x", oX_Default_2);
  Annu_2.setFloat( "y", oY_Default_2);
  Annu_2.setInt( "颜色", C_Default_2);

  saveTable(presetTable, "data/preset.csv");
}


void keyPressed() {
  if (key =='t') {
    testMode = !testMode;
  }

  if (key == '1') {
    dspMode = "Default_MODE";
    mouseTest = false;
  }

  if (key == '2') {
    dspMode = "S_SCAPE_MODE";
    mouseTest = true;
  }

  if (key == '3') {
    dspMode = "S_TRACK_MODE";
  }

  if (key =='4') {
    paths.showLine = false;
    paths.showPoint = false;
  }

  if (key=='k') {
    paths.newPath = true;
    paths.addLoc = true;
    paths.beginRecord = true;
  }

  if (key=='g') {
    paths.endRecord = true;
    paths.addLoc = false;
  }

  if (key == 'r') {
    pixel_per_mm = 0.5;
    //paths.Paths.clear();

    a_1_Default = 308.0;
    b_1_Default = 160.0;
    w_1_Defaulte = 94;
    oX_Default_1 = 440;
    oY_Default_1 = 205;
    a_2_Default = 164.0;
    b_2_Default = 120.0;
    w_2_Defaulte = 116;
    oX_Default_2 = 453;
    oY_Default_2 = 205;
    C_Default_1 = color(0, 20, 80, 150);
    C_Default_2 = color(80, 20, 10, 150);
  }
}

////存入开关
//void keyPressed() {

//}
