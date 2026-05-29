#include <Servo.h>
#include <Wire.h> 
#include <LiquidCrystal_I2C.h>


const int trigPin = 7;  
const int echoPin = 8;  
Servo myServo;


const int ledGreen = 11;
const int ledYellow = 10;
const int ledRed = 9;


const int buzzerPin = 3; 


LiquidCrystal_I2C lcd(0x27, 16, 2); 

void setup() {
  
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  
  
  pinMode(ledGreen, OUTPUT);
  pinMode(ledYellow, OUTPUT);
  pinMode(ledRed, OUTPUT);
  pinMode(buzzerPin, OUTPUT);
  
  
  myServo.attach(6);    
  Serial.begin(9600);

  
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Radar System");
  lcd.setCursor(0, 1);
  lcd.print("Online...");
}

void loop() {
  
  for(int i=0; i<=180; i+=2){  
    myServo.write(i);
    delay(15); 
    float distanceCm = getDistanceCm();
    
    Serial.print(distanceCm);
    Serial.print(",");
    Serial.println(i);
    
    checkSerialFromProcessing(); 
  }
  
 
  for(int i=180; i>0; i-=2){  
    myServo.write(i);
    delay(15);
    float distanceCm = getDistanceCm();
    
    Serial.print(distanceCm);
    Serial.print(",");
    Serial.println(i);
    
    checkSerialFromProcessing(); 
  }
}


float getDistanceCm() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  
  long duration = pulseIn(echoPin, HIGH, 12000); 
  if (duration == 0) {
    return 999; 
  }
  return (duration * 0.0343) / 2.0;
}


void checkSerialFromProcessing() {
  if (Serial.available() > 0) {
    float closestDist = Serial.parseFloat(); 
    
    lcd.clear(); 
    
    
    lcd.setCursor(0, 0);
    lcd.print("Closest: ");
    if (closestDist >= 200 || closestDist <= 0) {
      lcd.print("CLEAR");
    } else {
      lcd.print(closestDist, 1);
      lcd.print("cm");
    }
    
    lcd.setCursor(0, 1);
    
    
    if (closestDist <= 50.0 && closestDist > 0) {
      lcd.print("WARN: Obj Detect"); 
      digitalWrite(ledRed, HIGH);
      digitalWrite(ledYellow, LOW);
      digitalWrite(ledGreen, LOW);
      
      digitalWrite(buzzerPin, HIGH); 
    } 
    
    else if (closestDist > 50.0 && closestDist <= 100.0) {
      lcd.print("Obj Approaching");
      digitalWrite(ledRed, LOW);
      digitalWrite(ledYellow, HIGH);
      digitalWrite(ledGreen, LOW);
      
      digitalWrite(buzzerPin, LOW);  
    } 
    
    else {
      lcd.print("System Secure");
      digitalWrite(ledRed, LOW);
      digitalWrite(ledYellow, LOW);
      digitalWrite(ledGreen, HIGH);
      
      digitalWrite(buzzerPin, LOW);  
    }
  }
}
