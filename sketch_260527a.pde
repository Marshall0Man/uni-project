import processing.serial.*;
import java.net.*; // استدعاء مكتبة الشبكات

Serial myPort;        
String data = "";     
float distance = 0;   
float angle = 0;      

float maxDistance = 200; 

float[] radarDistances = new float[181];
float currentMinDistance = 999;
float displayedMinDistance = 0;
float lastAngle = 0;


DatagramSocket udpSocket;
InetAddress nodeRedAddress;
int nodeRedPort = 1234; 


boolean alarmSent = false; 

void setup() {
  fullScreen();
  smooth();
  
  for (int i = 0; i <= 180; i++) {
    radarDistances[i] = 999;
  }
  
  
  try {
    udpSocket = new DatagramSocket();
    nodeRedAddress = InetAddress.getByName("localhost"); 
  } catch (Exception e) {
    println("خطأ في تهيئة اتصال UDP: " + e.getMessage());
  }
  
  try {
    myPort = new Serial(this, "COM3", 9600); 
    myPort.bufferUntil('\n');
    println("تم الاتصال بنجاح بالأردوينو على المنفذ: COM3");
  } catch (Exception e) {
    println("خطأ: لم يتم العثور على الأردوينو في المنفذ COM3");
  }
}

void draw() {
  background(10, 16, 12); 
  
  float centerX = width / 2;
  float centerY = height * 0.65;     
  float radarRadius = height * 0.45; 

  drawRadarSectors(centerX, centerY, radarRadius);
  drawRadarGrid(centerX, centerY, radarRadius);
  drawRadarSweepLine(centerX, centerY, radarRadius, angle);
  
  drawDualDisplay(centerX, height * 0.85);
}

// دالة إرسال الرسائل عبر الـ UDP إلى Node-RED
void sendUdpMessage(String message) {
  try {
    byte[] sendData = message.getBytes();
    DatagramPacket sendPacket = new DatagramPacket(sendData, sendData.length, nodeRedAddress, nodeRedPort);
    udpSocket.send(sendPacket);
  } catch (Exception e) {
    println("خطأ أثناء إرسال حزمة UDP: " + e.getMessage());
  }
}

void drawRadarSectors(float cx, float cy, float r) {
  noStroke();
  for (int i = 0; i < 180; i++) {
    float d = radarDistances[i];
    float radStart = radians(i);
    float radEnd = radians(i + 2); 
    
    if (d >= maxDistance || d <= 0) {
      fill(80, 15, 15, 15); 
      arc(cx, cy, r*2, r*2, -radEnd, -radStart);
    } else {
      float targetRadius = (d / maxDistance) * r;
      fill(0, 130, 50, 130); 
      arc(cx, cy, targetRadius*2, targetRadius*2, -radEnd, -radStart);
      fill(180, 30, 30, 35); 
      arc(cx, cy, r*2, r*2, -radEnd, -radStart);
      fill(10, 16, 12);
      arc(cx, cy, targetRadius*2, targetRadius*2, -radEnd, -radStart);
    }
  }
}

void drawRadarGrid(float cx, float cy, float r) {
  noFill();
  stroke(0, 200, 100, 100); 
  strokeWeight(1.5);
  arc(cx, cy, r*2, r*2, PI, TWO_PI);
  stroke(0, 200, 100, 50); 
  arc(cx, cy, r*1.5, r*1.5, PI, TWO_PI);
  arc(cx, cy, r, r, PI, TWO_PI);
  arc(cx, cy, r*0.5, r*0.5, PI, TWO_PI);
  
  stroke(0, 200, 100, 120);
  line(cx - r - 20, cy, cx + r + 20, cy);
  
  stroke(0, 200, 100, 40);
  for (int a = 30; a <= 150; a += 30) {
    float rad = radians(a);
    fill(0, 220, 100, 150);
    textSize(14);
    textAlign(CENTER, CENTER);
    text(a + "°", cx + cos(-rad) * (r + 20), cy + sin(-rad) * (r + 20));
    line(cx, cy, cx + cos(-rad) * r, cy + sin(-rad) * r);
  }
  text("0°", cx + r + 20, cy);
  text("90°", cx, cy - r - 20);
  text("180°", cx - r - 20, cy);
}

void drawRadarSweepLine(float cx, float cy, float r, float angleDeg) {
  float rad = radians(angleDeg);
  float sweepX = cx + cos(-rad) * r;
  float sweepY = cy + sin(-rad) * r;
  stroke(0, 255, 150, 240);
  strokeWeight(4.0);
  line(cx, cy, sweepX, sweepY);
}

void drawDualDisplay(float cx, float y) {
  float boxWidth = 280;
  float boxHeight = 75;
  float spacing = 50; 
  drawSingleBox(cx - boxWidth - (spacing / 2), y, boxWidth, boxHeight, "LIVE DISTANCE", distance, false);
  drawSingleBox(cx + (spacing / 2), y, boxWidth, boxHeight, "CLOSEST SCAN DISTANCE", displayedMinDistance, true);
}

void drawSingleBox(float x, float y, float w, float h, String label, float val, boolean isClosestBox) {
  noFill();
  stroke(0, 150, 75, 60);
  strokeWeight(3);
  rect(x - 4, y - 4, w + 8, h + 8, 8);
  fill(15, 25, 20); 
  stroke(0, 255, 120); 
  strokeWeight(2);
  rect(x, y, w, h, 5);
  fill(0, 200, 100, 180);
  textSize(13);
  textAlign(CENTER);
  text(label, x + w/2, y - 12);
  textAlign(CENTER, CENTER);
  
  if (val >= maxDistance || val <= 0) {
    if (isClosestBox && val == 999) {
      fill(0, 180, 255);
      textSize(28);
      text("CLEAR", x + w/2, y + h/2 + 2);
    } else {
      fill(255, 60, 60);
      textSize(24);
      text("OUT OF RANGE", x + w/2, y + h/2 + 2);
    }
  } else {
    fill(0, 255, 120);
    textSize(32);
    text(nf(val, 0, 1) + " cm", x + w/2, y + h/2 - 2); 
  }
}

void serialEvent(Serial myPort) {
  try {
    while (myPort.available() > 0) { 
      data = myPort.readStringUntil('\n');
      if (data != null) {
        data = trim(data);
        float[] list = float(split(data, ','));
        if (list.length >= 2) {
          if (!Float.isNaN(list[0]) && !Float.isNaN(list[1])) {
            distance = list[0]; 
            angle = list[1];    
            
            int angleIdx = int(angle);
            if (angleIdx >= 0 && angleIdx <= 180) {
              radarDistances[angleIdx] = distance;
            }
            
            if (distance > 0 && distance < maxDistance) {
              if (distance < currentMinDistance) {
                currentMinDistance = distance; 
              }
            }
            
            if (angle == 0 && lastAngle > 0) {
              displayedMinDistance = currentMinDistance; 
              
              myPort.write(str(displayedMinDistance) + "\n"); 
              
              // --- منطق الخطر ومنع التكرار المحدث ---
              if (displayedMinDistance <= 50.0 && displayedMinDistance > 0) {
                // إذا كان الجسم قريب، ولم نقم بإرسال إشعار بعد خلال هذه المواجهة
                if (!alarmSent) { 
                  sendUdpMessage("WARNING: Object detected at " + displayedMinDistance + " cm");
                  alarmSent = true; // نرفع الراية؛ تم الإرسال ولن يتكرر!
                }
              } else {
                // إذا أصبحت المسافة آمنة (أكبر من 50 سم أو خالية)
                if (alarmSent) {
                  sendUdpMessage("SECURE"); // إرسال طمأنينة لنود ريد (اختياري)
                  alarmSent = false; // إعادة تصفير الراية؛ الرادار جاهز للمواجهة القادمة!
                }
              }
              
              currentMinDistance = 999;                 
            }
            lastAngle = angle; 
          }
        }
      }
    }
  } catch(Exception e) {}
}
