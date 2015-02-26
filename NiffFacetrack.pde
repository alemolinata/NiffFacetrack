// A NIFF!
// A Niff doesn't like it when you scream or make loud noises. He becomes very uneasy, really.

// Importing minim lib
import ddf.minim.*;
// Importing OpenCV libs for face detection from camera
import gab.opencv.*;
import processing.video.*;
import java.awt.*;

// Defining Minim environment and use of mic
Minim minim;
AudioInput in;

// Creating instances of OpenCV and video capture.
Capture video;
OpenCV opencv;
float xFace;
float yFace;

// Set screen size
int dWidth;
int dHeight;

// Floats for changing LEFT & RIGHT size of eyes
float lSize;
float rSize;
// floats for changing the background colour
float backRColor;
float backLColor;

// Static distances for drawing face
float xC; //center in X axis
float yC; //center in Y axis
float d;
float sL; //shadow length AND stroke

// Values for volume and for the actual mood, to smooth the reactions
float lVol;
float rVol;
float lMood;
float rMood;
float lMoodPrev;
float rMoodPrev;

// Floats for LEFT & RIGHT bezier points used to change mouth-shape
float lBezier;
float rBezier;

// Values for vectors that detect movement of mouse
PVector mMouse = new PVector(mouseX, mouseY);
PVector mCircleCenter = new PVector(width/2, height/2);
PVector mResult = new PVector();
float mMaxLength;

void setup(){
  // Setup the microphone
  minim = new Minim(this);
  in = minim.getLineIn();
  size( displayWidth, displayHeight );
  xC = width/2;
  yC = height/2;
  
  video = new Capture(this, width, height);
  opencv = new OpenCV(this, width, height);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE); 
  
  video.start();
  
  dWidth = displayWidth;
  dHeight = displayHeight;
  d = dHeight/8;
  sL = dHeight/100;
  
  mMaxLength = dHeight/2;
  
}

void draw() {
  smooth();
  rVol = in.right.level();
  lVol = in.left.level();
  rMood += ( rVol - rMood ) * 0.5;
  lMood += ( lVol - lMood ) * 0.5;

  // BACKGROUND
  // Mapping values to be used in changing background colour according to volume. As the Niff stresses it gets red
  backRColor = map(rMood,0,1,0,255);
  backLColor = map(lMood,0,1,255,0);
  // changing background colour
  background(backRColor, backLColor/2,  backLColor);
  
  // EYES
  // Mapping values to be used in sizing eyes according to volume  
  lSize = map(lMood,0,1,d*2,0);
  rSize = map(rMood,0,1,d*2,0);
  noStroke();
  
  // Drawing shadow for eyes
  fill(0,0,0,80);
  ellipse(width/3, yC-d/2+sL, lSize, lSize);
  ellipse(width/3*2, yC-d/2+sL, rSize, rSize);
  
  // Drawing eyes
  fill(255);
  ellipse(width/3, yC-d/2, lSize, lSize);
  ellipse(width/3*2, yC-d/2, rSize, rSize);

  
  // MOUTH
  // Mouth moves according to volume as well. When it's quiet it's happy, medium amplitude he is serious, and high volume, stressed.
  noFill();
  strokeWeight(sL);
  
  // Mapping values for RIGHT side of the mouth.
  // It moves up to make a straight line as it gets closer to the mid-tones, but then goes down again as it gets louder
  if(in.left.level()<0.5){
    rBezier = map(lMood, 0, 0.5, d, 0);
  }
  else{
    rBezier = map(lMood, 0.5, 1, 0, d);
  }
  // Mapping values for LEFT side of the mouth.
  // It moves down when it's quiet and up when it's louder
  lBezier = map(rMood, 0, 1, d, -d);
  
  // Drawing shadow of mouth
  stroke(0,80);
  bezier(xC-d, yC+d+sL, xC-d/2, yC+lBezier+d+sL, xC+d/2, yC+rBezier+d+sL, xC+d, yC+d+sL);
  
  // Drawing actual mouth
  stroke(255);
  bezier(xC-d, yC+d, xC-d/2, yC+lBezier+d, xC+d/2, yC+rBezier+d, xC+d, yC+d);
  
  // PUPILS
  // Calculations to track mouse position and convert it to eye movement.
  
  pushMatrix();
  
  scale(-1, 1);
  translate(-width, 0);
  opencv.loadImage(video);

  Rectangle[] faces = opencv.detect();
  
  popMatrix();
  
  xFace = width/2;
  yFace = height/2;
  float maxWidth = 0;
  if(faces.length >= 1){
    for (int i = 0; i < faces.length; i++) {
      if( faces[i].width > maxWidth){
        xFace = width - (faces[i].x + faces[i].width/2);
        yFace = faces[i].y + faces[i].height/2;
        maxWidth = faces[i].width;
      }
    }
  }
  
  float mX = width - mCircleCenter.x;
  
  mMouse = new PVector(xFace, yFace);
  mCircleCenter = new PVector(xC, yC);
  mResult = new PVector();

  mResult.set(mMouse.x - mCircleCenter.x, mMouse.y - mCircleCenter.y);

  float mLength = mResult.mag();
  mLength = max(0, min(mLength, mMaxLength));
  mLength /= mMaxLength;

  float mAngle = mResult.heading(); // atan2(mResult.y, mResult.x);
  float mCircleRadius = lSize*0.36;

  PVector mPupil = new PVector();
  mPupil.y = sin(mAngle) * mCircleRadius * mLength;
  mPupil.x = cos(mAngle) * mCircleRadius * mLength;
  mPupil.add(mCircleCenter);
  
  // Drawing pupils
  fill(200);
  noStroke();
  ellipse(mPupil.x-width/6, mPupil.y-d/2, lSize/6, lSize/6);
  ellipse(mPupil.x+width/6, mPupil.y-d/2, rSize/6, rSize/6);
  
  lMoodPrev = lMood;
  rMoodPrev = rMood;
}

void captureEvent(Capture c) {
  c.read();
}


