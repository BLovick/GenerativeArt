/*
Copyright (c) 2016 Tobias Wehrum <Tobias.Wehrum@dragonlab.de>
Distributed under the MIT License. (See accompanying file LICENSE or copy at http://opensource.org/licenses/MIT)
This notice shall be included in all copies or substantial portions of the Software.

Controls:
- Left/right to go back/forward in the current track.
- Up to restart.
- Down to pause/unpause.
- Space to load a new configuration.

XML:
- song: MOD file.
- scaling: Amplitude vibration scaling.
- rotationSpeed: Rotational speed.
- lowerPitch: The pitch which should be shown as 0%.
- upperPitch: The pithc which should be shown as 100%.
- gradient: A gradient image file.
- gradientReverse: true/false - should the gradient be inverted?

Color scheme credits:
- "Pop Is Everything" by jen_savage: http://www.colourlovers.com/palette/7315/Pop_Is_Everything

Music credits:
- chiptune, phantasmagoria, rsectro and zapped_out by 4mat
- Rivendell by radix
*/

int decorationCircleOffset = 10;

float extents;
float visualRadius;
float rotationAngle;
float scale = 1;

float smoothedRms;

float rotationSpeed;

int mode;
float arcShineAlpha;
float arcInnerAlpha;
float backgroundClearAlpha;
float backgroundCircleClearAlpha;
float backgroundCircleClearRadius; 
boolean decorationActive;
boolean decorationFilled;
float vibrationFactor;

boolean newSong;

void setup()
{
  //size(displayWidth, displayHeight);
  //size(600, 600);
  fullScreen();
  noCursor();

  //colorMode(HSB, 360, 255, 255, 255);
  //blendMode(ADD);

  audioSetup();
  reset();

  extents = min(width, height);
  visualRadius = extents / 2 * 0.8;
  
  backgroundCircleClearRadius = visualRadius * 1.2;
  //backgroundCircleClearRadius = (extents/4) * 1.9 + decorationCircleOffset * -1;

  frameRate(30);
}

void prepare(XML xml)
{
  prepareAnalysis(xml);
  
  rotationSpeed = xml.getFloat("rotationSpeed", 1);
  
  mode = xml.getInt("mode", 1);
  
  switch (mode)
  {
    default:
      arcShineAlpha = 5;
      arcInnerAlpha = 15;
      backgroundClearAlpha = 10;
      backgroundCircleClearAlpha = 50;
      decorationActive = false;
      decorationFilled = false;
      vibrationFactor = 1;
      break;
    
    case 2:
      arcShineAlpha = 5;
      arcInnerAlpha = 15;
      backgroundClearAlpha = 10;
      backgroundCircleClearAlpha = 0;
      decorationActive = false;
      decorationFilled = false;
      vibrationFactor = 0;
      break;

    case 3:
      arcShineAlpha = 0;
      arcInnerAlpha = 15;
      backgroundClearAlpha = 50;
      backgroundCircleClearAlpha = 0;
      decorationActive = true;
      decorationFilled = true;
      vibrationFactor = 1;
      break;
  }

  /*
  int extents = min(width, height);
  cellWidth = extents / cellCountX;
  cellHeight = extents / cellCountY;
  int cellStartX = (width - cellCountX * cellWidth) / 2;
  int cellStartY = (height - cellCountY * cellHeight) / 2;
  for (int x = 0; x < cellCountX; x++)
  {
    for (int y = 0; y < cellCountY; y++)
    {
      int posX = cellStartX + cellWidth * x;
      int posY = cellStartY + cellHeight * y;
    }
  }
  */
  rotationAngle = 0;

  newSong = true; 
}

void executeDraw()
{
  if (newSong)
  {
    background(50);
    fill(0, 50);
    noStroke();
    for (int i = 0; i < 10; i++)
      rect(0, 0, width, height);
      
    newSong = false;
  }
  
  rotationAngle += 0.03 * rotationSpeed;

  resetBackground();

  processSamples();

  smoothedRms *= 0.9;
  smoothedRms = max(smoothedRms, rms);
  scale = (1 + smoothedRms * vibrationFactor) * scaling;

  for (ChannelInfo channel : channels)
    channel.update();

  if (decorationActive)
    drawDecoration();

  for (ChannelInfo channel : channels)
  {
    for (InstrumentChannelInfo instrumentChannelInfo : channel.instrumentChannelInfos)
    {
      instrumentChannelInfo.draw();
    }
  }
  
  //background(0);
  //debugDrawPeakAndRms();
  //debugDrawSamples();
  //debugDrawChannelPitch();
  //debugDrawChannelInstruments();
}

void resetBackground()
{
  noStroke();
  if (backgroundClearAlpha > 0)
  {
    fill(0, backgroundClearAlpha);
    rect(0, 0, width, height);
  }
  
  //background(0);
  
  if (backgroundCircleClearAlpha > 0)
  {
    fill(0, backgroundCircleClearAlpha);
    ellipse(width/2, height/2, backgroundCircleClearRadius * 2, backgroundCircleClearRadius * 2);
  }
}

void drawDecoration()
{
  pushMatrix();
  translate(width/2, height/2);
  //rotate(rotationAngle);
  /*
  int lineCount = 20;
  float angleDelta = lineCount / (PI / 2);
  int lineRadius = width + height;
  for (int i = 0; i < lineCount; i++)
  {
    line(-lineRadius, 0, lineRadius, 0);
    rotate(angleDelta);
  }
  */
  int arcPointCount = 50;
  float ellipseExtents = (extents/2) * 1.9;
  float ellipseExtentsInner = ellipseExtents + decorationCircleOffset * 2;
  
  stroke(255, 50);
  strokeWeight(1);
  noFill();
  
  float arcAngleOffset = (float)Math.asin(decorationCircleOffset/ellipseExtentsInner)*2;
  float arcAngleOffsetPart = (PI/2-arcAngleOffset*2) / (arcPointCount - 1);
  
  for (int i = 0; i < 4; i++)
  {
    PVector arcFrom = new PVector((float)Math.cos(arcAngleOffset) * ellipseExtentsInner/2, (float)Math.sin(arcAngleOffset) * ellipseExtentsInner/2);
    PVector arcTo = new PVector(arcFrom.y, arcFrom.x);
    //arc(0, 0, ellipseExtentsInner, ellipseExtentsInner, arcAngleOffset, PI/2 - arcAngleOffset);
    //line(arcFrom.x, arcFrom.y, arcTo.x, arcTo.y);
    //line(arcFrom.x, arcFrom.y, width+height, arcFrom.y);
    //line(arcTo.x, arcTo.y, arcTo.x, width+height);
    
    beginShape();
    vertex(width+height, arcFrom.y);
    vertex(arcFrom.x, arcFrom.y);
    for (int j = 1; j < arcPointCount - 1; j++)
    {
      vertex((float)Math.cos(arcAngleOffset + arcAngleOffsetPart * j) * ellipseExtentsInner/2,
             (float)Math.sin(arcAngleOffset + arcAngleOffsetPart * j) * ellipseExtentsInner/2);
    }
    vertex(arcTo.x, arcTo.y);
    vertex(arcTo.x, width+height);
    vertex(width+height, width+height);
    endShape();
    
    stroke(255, 50);
    
    line(ellipseExtents/2, 0, width+height, 0);
    rotate(PI/2);
  }
  
  ellipseExtentsInner += decorationCircleOffset * 2;
  arcAngleOffset = (float)Math.asin(decorationCircleOffset*2/ellipseExtentsInner)*2;
  arcAngleOffsetPart = (PI/2-arcAngleOffset*2) / (arcPointCount - 1);
  
  for (int i = 0; i < 4; i++)
  {
    PVector arcFrom = new PVector((float)Math.cos(arcAngleOffset) * ellipseExtentsInner/2, (float)Math.sin(arcAngleOffset) * ellipseExtentsInner/2);
    PVector arcTo = new PVector(arcFrom.y, arcFrom.x);
    
    noStroke();
    if (decorationFilled)
    {
      fill(30);
    }
    else
    {
      noFill();
    }
    
    beginShape();
    vertex(width+height, arcFrom.y);
    vertex(arcFrom.x, arcFrom.y);
    for (int j = 1; j < arcPointCount - 1; j++)
    {
      vertex((float)Math.cos(arcAngleOffset + arcAngleOffsetPart * j) * ellipseExtentsInner/2,
             (float)Math.sin(arcAngleOffset + arcAngleOffsetPart * j) * ellipseExtentsInner/2);
    }
    vertex(arcTo.x, arcTo.y);
    vertex(arcTo.x, width+height);
    vertex(width+height, width+height);
    endShape();

    rotate(PI/2);
  }

  stroke(255, 50);
  noFill();
  
  ellipse(0, 0, ellipseExtents, ellipseExtents);
  
  ellipseExtents -= decorationCircleOffset * 2;
  ellipse(0, 0, ellipseExtents, ellipseExtents);

  popMatrix();
}

class InstrumentChannelInfo
{
  ChannelInfo channel;
  InstrumentData instrument;
  float value;
  float visible;
  //float angle;
  boolean active;
  PVector[] prevPosRotArr;
  PVector[] prevPosRotArrCenter;

  InstrumentChannelInfo(ChannelInfo channel, InstrumentData instrument)
  {
    this.channel = channel;
    this.instrument = instrument;
    prevPosRotArr = new PVector[floor(160/module.get_num_channels())];
    prevPosRotArrCenter = new PVector[prevPosRotArr.length];
  }

  void update()
  {
    if (active)
    {
      if (channel.isSilent())
      {
        value = 0;
      }
      else
      {
        value = channel.getCurrentStepLogMapped();
      }
    }
    else
    {
      value = 0;
    }
  }

  void draw()
  {
    color c = getColor((float)instrument.counter / (usedInstruments.size()-1));
    stroke(c, 255);
    if (arcInnerAlpha > 0)
    {
      fill(c, arcInnerAlpha);
    }
    else
    {
      noFill();
    }
    strokeCap(NORMAL);
    
    float angle = rotationAngle + ((float)channel.index/channels.length) * (PI*2);
    
    PVector center = new PVector(width/2f, height/2f);
    
    float satelliteDistanceInner = 20;
    float satelliteDistanceOuter = 20;
    float distance = satelliteDistanceInner + value * (visualRadius - satelliteDistanceInner - satelliteDistanceOuter);
    float dx = cos(angle);
    float dy = sin(angle);
    float x = center.x + dx * distance;
    float y = center.y + dy * distance;
    for (int j = 0; j < prevPosRotArr.length-1; j++)
    {
      prevPosRotArr[j] = prevPosRotArr[j+1];
      prevPosRotArrCenter[j] = prevPosRotArrCenter[j+1];
    }
    
    prevPosRotArr[prevPosRotArr.length-1] = new PVector(dx * distance, dy * distance);
    prevPosRotArrCenter[prevPosRotArr.length-1] = new PVector(dx * satelliteDistanceInner,
                                                              dy * satelliteDistanceInner);
    if (value == 0)
    {
      prevPosRotArr[prevPosRotArr.length-1] = null;
    }
    
    /*
    if (prevPosRotArr[0] != null)
      line(width/2, height/2, prevPosRotArr[0].x, prevPosRotArr[0].y);
    */
    
    PVector firstDelta;
    PVector lastDelta;
    
    int lastFrom = 0;
    int lastTo = 0;
    PVector lastDrawn = null;
    for (int j = 0; j < prevPosRotArr.length; j++)
    {
      PVector delta = prevPosRotArr[j];
      if (delta != null)
      {
        if (lastDrawn == null)
        {
          PVector shortDelta = new PVector(delta.x, delta.y);
          shortDelta.normalize();
          shortDelta.mult(satelliteDistanceInner*scale);
          beginShape();
          vertex(center.x + shortDelta.x, center.y + shortDelta.y);
          lastDrawn = new PVector();
          lastFrom = j;
        }

        lastDrawn.x = delta.x;
        lastDrawn.y = delta.y;
        lastTo = j;
        
        PVector copy = new PVector(delta.x, delta.y);
        float len = copy.mag();
        copy.mult((len*scale)/len);
        
        vertex(center.x + copy.x, center.y + copy.y);
      }
      else if (lastDrawn != null)
      {
        closeShape(c, center, lastFrom, lastTo);
        lastDrawn = null;
      }
      /*
      PVector to = prevPosRotArr[j+1];
      if ((from != null) && (to != null))
        line(from.x, from.y, to.x, to.y);
      */
    }
    if (lastDrawn != null)
    {
      closeShape(c, center, lastFrom, lastTo);
      /*
      lastDrawn.normalize();
      lastDrawn.mult(satelliteDistanceInner*scale);
      vertex(center.x + lastDrawn.x, center.y + lastDrawn.y);
      for (int k = lastTo; k >= lastFrom; k--)
      {
        PVector delta = prevPosRotArrCenter[k];
        PVector copy = new PVector(delta.x, delta.y);
        float len = copy.mag();
        copy.mult((len*scale)/len);
        vertex(center.x + copy.x, center.y + copy.y);
      }
      endShape(CLOSE);
      */
      lastDrawn = null;
    }
    
    //if (active)
    //  ellipse(x, y, 20, 20);
    
    //angle += PI*2 / prevPosRotArr.length;
    
    /*
    float blockHeight = 10;
    float rectWidth = width / channels.length;
    float leftX = channel.index * rectWidth;
    float y = (1 - value) * height;
    rect(leftX, y - blockHeight / 2, rectWidth, blockHeight);
    */
  }
  
  void closeShape(color c, PVector center, int lastFrom, int lastTo)
  {
    for (int k = lastTo; k >= lastFrom; k--)
    {
      PVector delta = prevPosRotArrCenter[k];
      PVector copy = new PVector(delta.x, delta.y);
      float len = copy.mag();
      copy.mult((len*scale)/len);
      vertex(center.x + copy.x, center.y + copy.y);
    }
    endShape(CLOSE);
    
    if (arcShineAlpha > 0)
    {
      noStroke();
      //stroke(c, 100);
      fill(c, arcShineAlpha);
      
      beginShape();
      for (int k = lastTo; k >= lastFrom; k--)
      {
        PVector delta = prevPosRotArrCenter[k];
        PVector copy = new PVector(delta.x, delta.y);
        float len = copy.mag();
        copy.mult((len*scale)/len);
        vertex(center.x + copy.x, center.y + copy.y);
      }
      PVector fromCopy = new PVector(prevPosRotArrCenter[lastFrom].x, prevPosRotArrCenter[lastFrom].y);
      PVector toCopy = new PVector(prevPosRotArrCenter[lastTo].x, prevPosRotArrCenter[lastTo].y);
      fromCopy.normalize();
      toCopy.normalize();
      float extraDistance = width + height;
      //vertex(center.x, center.y);
      vertex(center.x + fromCopy.x * extraDistance, center.y + fromCopy.y * extraDistance);
      vertex(center.x + toCopy.x * extraDistance, center.y + toCopy.y * extraDistance);
      endShape(CLOSE);
    }
    
    stroke(c, 255);
    if (arcInnerAlpha > 0)
    {
      fill(c, arcInnerAlpha);
    }
    else
    {
      noFill();
    }
  }
}